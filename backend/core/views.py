from datetime import timedelta
import uuid

from django.contrib.auth.models import User
from django.db import connection
from django.db.models import Count, Sum
from django.utils import timezone
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView

from core.models import (
    Booking,
    BookingStatus,
    EquipmentItem,
    FeedbackEntry,
    MembershipPlan,
    MembershipRecord,
    Notification,
    PaymentRecord,
    PaymentStatus,
    Profile,
    TrainerProfile,
    UserRole,
)
from core.permissions import IsAdminOrReadOnly, IsAdminRole, is_admin_user
from core.serializers import (
    BookingSerializer,
    EquipmentItemSerializer,
    FeedbackEntrySerializer,
    MembershipPlanSerializer,
    MembershipRecordSerializer,
    NotificationSerializer,
    PaymentRecordSerializer,
    RegisterSerializer,
    RenewMembershipSerializer,
    TrainerProfileSerializer,
    UserSerializer,
    EmailTokenObtainPairSerializer,
)
from core.mpesa import stk_push, MPesaError
from rest_framework.permissions import AllowAny
from django.http import HttpResponse, JsonResponse
from io import BytesIO

# optional server-side export libs
try:
    from reportlab.lib.pagesizes import letter
    from reportlab.pdfgen import canvas
except Exception:
    letter = None

try:
    from openpyxl import Workbook
except Exception:
    Workbook = None


class EmailTokenObtainPairView(TokenObtainPairView):
    serializer_class = EmailTokenObtainPairSerializer


class HealthAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        database = "unknown"
        try:
            connection.ensure_connection()
            database = "ok" if connection.is_usable() else "unavailable"
        except Exception:
            database = "unavailable"
        return Response(
            {
                "status": "ok",
                "service": "fitflow-api",
                "database": database,
                "time": timezone.now(),
            }
        )


class RegisterAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(RegisterSerializer(user).data, status=status.HTTP_201_CREATED)


class MeAPIView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user, context={"request": request}).data)

    def patch(self, request):
        serializer = UserSerializer(
            request.user,
            data=request.data,
            partial=True,
            context={"request": request},
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)


class UserViewSet(viewsets.ModelViewSet):
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = User.objects.select_related("profile").order_by("id")
        if is_admin_user(self.request.user):
            return queryset
        return queryset.filter(id=self.request.user.id)


class MembershipPlanViewSet(viewsets.ModelViewSet):
    queryset = MembershipPlan.objects.all()
    serializer_class = MembershipPlanSerializer
    permission_classes = [IsAdminOrReadOnly]


class MembershipRecordViewSet(viewsets.ModelViewSet):
    serializer_class = MembershipRecordSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = MembershipRecord.objects.select_related("user", "plan")
        if is_admin_user(self.request.user):
            return queryset
        return queryset.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=False, methods=["post"], url_path="renew")
    def renew(self, request):
        serializer = RenewMembershipSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        record = serializer.save()
        return Response(MembershipRecordSerializer(record).data, status=status.HTTP_201_CREATED)


class MpesaStkPushAPIView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        phone = request.data.get("phone")
        amount = request.data.get("amount")
        plan_name = request.data.get("plan_name")
        duration_days = request.data.get("duration_days")
        account_ref = request.data.get("account_reference", "GYM")
        if not phone or not amount or not plan_name:
            return Response({"detail": "phone, amount and plan_name are required"}, status=400)

        # create a pending payment record to link with the STK push
        reference = f"STK-{uuid.uuid4().hex[:10].upper()}"
        payment = PaymentRecord.objects.create(
            user=request.user,
            method="M-Pesa STK",
            amount=amount,
            status=PaymentStatus.PENDING,
            reference=reference,
            metadata={
                "phone": phone,
                "plan_name": plan_name,
                "duration_days": duration_days,
            },
        )

        try:
            resp = stk_push(phone=str(phone), amount=int(amount), account_reference=account_ref)
        except MPesaError as e:
            payment.metadata.update({"error": str(e)})
            payment.save(update_fields=["metadata"])  # keep record of failure
            return Response({"detail": str(e)}, status=500)

        # record Daraja identifiers for mapping later in callback
        merchant_id = resp.get("MerchantRequestID")
        checkout_id = resp.get("CheckoutRequestID")
        meta = payment.metadata or {}
        meta.update({"merchant_request_id": merchant_id, "checkout_request_id": checkout_id, "daraja_response": resp})
        payment.metadata = meta
        payment.save(update_fields=["metadata"])

        return Response({"success": True, "reference": payment.reference, "merchant_request_id": merchant_id, "checkout_request_id": checkout_id})


class MpesaCallbackAPIView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        # Daraja posts a JSON payload with Body.stkCallback
        body = request.data or {}
        stk = body.get("Body", {}).get("stkCallback")
        if not stk:
            return Response({"detail": "invalid callback"}, status=400)

        merchant_req = stk.get("MerchantRequestID")
        checkout_req = stk.get("CheckoutRequestID")
        result_code = stk.get("ResultCode")
        result_desc = stk.get("ResultDesc")

        # try to find the pending payment by checkout or merchant id
        payment = None
        candidates = PaymentRecord.objects.filter(status=PaymentStatus.PENDING)
        for p in candidates:
            md = p.metadata or {}
            if md.get("checkout_request_id") == checkout_req or md.get("merchant_request_id") == merchant_req:
                payment = p
                break

        if not payment:
            return Response({"detail": "payment record not found"}, status=404)

        # attach callback info
        md = payment.metadata or {}
        md.update({"callback_result_code": result_code, "callback_result_desc": result_desc})

        if int(result_code) == 0:
            # success -> parse metadata items
            items = stk.get("CallbackMetadata", {}).get("Item", [])
            parsed = {item.get("Name"): item.get("Value") for item in items if item.get("Name")}
            md.update({"callback_data": parsed})
            payment.status = PaymentStatus.CONFIRMED
            payment.metadata = md
            payment.save(update_fields=["status", "metadata", "updated_at"])

            # create membership now using stored plan info
            plan_name = md.get("plan_name")
            duration_days = md.get("duration_days") or 0
            try:
                plan = MembershipPlan.objects.get(name=plan_name)
                started_at = timezone.now()
                membership = MembershipRecord.objects.create(
                    user=payment.user,
                    plan=plan,
                    started_at=started_at,
                    expires_at=started_at + timedelta(days=int(duration_days or plan.duration_days)),
                    status="Active",
                    payment_status=PaymentStatus.CONFIRMED,
                )
                payment.membership = membership
                payment.save(update_fields=["membership"])

                # add a notification for the user
                Notification.objects.create(
                    user=payment.user,
                    type="payment",
                    title="Payment received",
                    message=f"Payment {payment.reference} confirmed. Membership {plan.name} activated.",
                )
            except MembershipPlan.DoesNotExist:
                # plan missing; still keep payment confirmed
                pass
        else:
            md.update({"callback_data": stk.get("CallbackMetadata", {})})
            payment.status = PaymentStatus.FAILED
            payment.metadata = md
            payment.save(update_fields=["status", "metadata", "updated_at"])

        return Response({"ok": True})


class EquipmentItemViewSet(viewsets.ModelViewSet):
    queryset = EquipmentItem.objects.all()
    serializer_class = EquipmentItemSerializer
    permission_classes = [IsAdminOrReadOnly]


class TrainerProfileViewSet(viewsets.ModelViewSet):
    queryset = TrainerProfile.objects.select_related("user", "user__profile")
    serializer_class = TrainerProfileSerializer
    permission_classes = [IsAdminOrReadOnly]


class BookingViewSet(viewsets.ModelViewSet):
    serializer_class = BookingSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = Booking.objects.select_related("user", "equipment", "trainer", "trainer__user")
        user = self.request.user
        if is_admin_user(user):
            return queryset
        if getattr(getattr(user, "profile", None), "role", "") == UserRole.TRAINER:
            return queryset.filter(trainer__user=user)
        return queryset.filter(user=user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=["post"])
    def cancel(self, request, pk=None):
        booking = self.get_object()
        booking.status = BookingStatus.CANCELLED
        booking.save(update_fields=["status", "updated_at"])
        return Response(self.get_serializer(booking).data)

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def confirm(self, request, pk=None):
        booking = self.get_object()
        if not self._can_staff_update_booking(request.user, booking):
            return Response({"detail": "Only an admin or assigned trainer can confirm."}, status=403)
        booking.status = BookingStatus.CONFIRMED
        booking.save(update_fields=["status", "updated_at"])
        return Response(self.get_serializer(booking).data)

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def complete(self, request, pk=None):
        booking = self.get_object()
        if not self._can_staff_update_booking(request.user, booking):
            return Response({"detail": "Only an admin or assigned trainer can complete."}, status=403)
        booking.status = BookingStatus.COMPLETED
        booking.save(update_fields=["status", "updated_at"])
        return Response(self.get_serializer(booking).data)

    @staticmethod
    def _can_staff_update_booking(user, booking):
        if is_admin_user(user):
            return True
        return bool(booking.trainer_id and booking.trainer.user_id == user.id)


class PaymentRecordViewSet(viewsets.ModelViewSet):
    serializer_class = PaymentRecordSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = PaymentRecord.objects.select_related("user", "booking", "membership")
        if is_admin_user(self.request.user):
            return queryset
        return queryset.filter(user=self.request.user)

    def perform_create(self, serializer):
        reference = serializer.validated_data.get("reference") or f"PAY-{uuid.uuid4().hex[:10].upper()}"
        serializer.save(user=self.request.user, reference=reference)

    @action(detail=True, methods=["post"], permission_classes=[IsAdminRole])
    def confirm(self, request, pk=None):
        payment = self.get_object()
        payment.status = PaymentStatus.CONFIRMED
        payment.save(update_fields=["status", "updated_at"])
        if payment.booking_id:
            payment.booking.payment_status = PaymentStatus.CONFIRMED
            payment.booking.save(update_fields=["payment_status", "updated_at"])
        if payment.membership_id:
            payment.membership.payment_status = PaymentStatus.CONFIRMED
            payment.membership.save(update_fields=["payment_status"])
        return Response(self.get_serializer(payment).data)


class NotificationViewSet(viewsets.ModelViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = Notification.objects.select_related("user")
        if is_admin_user(self.request.user):
            return queryset
        return queryset.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=["post"])
    def mark_read(self, request, pk=None):
        notification = self.get_object()
        notification.is_read = True
        notification.save(update_fields=["is_read"])
        return Response(self.get_serializer(notification).data)


class FeedbackEntryViewSet(viewsets.ModelViewSet):
    serializer_class = FeedbackEntrySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = FeedbackEntry.objects.select_related("user")
        if is_admin_user(self.request.user):
            return queryset
        return queryset.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class AnalyticsAPIView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        today = timezone.localdate()
        start = timezone.now() - timedelta(days=6)
        confirmed_payments = PaymentRecord.objects.filter(status=PaymentStatus.CONFIRMED)

        revenue_trend = []
        for offset in range(6, -1, -1):
            day = today - timedelta(days=offset)
            total = (
                confirmed_payments.filter(created_at__date=day)
                .aggregate(value=Sum("amount"))
                .get("value")
                or 0
            )
            revenue_trend.append({"label": day.strftime("%a"), "value": float(total)})

        booking_trend = [
            {"label": item["time_slot"], "value": item["count"]}
            for item in Booking.objects.values("time_slot").annotate(count=Count("id")).order_by("time_slot")
        ]

        equipment_usage = []
        for item in EquipmentItem.objects.values("category").annotate(
            booked_total=Sum("booked"),
            capacity_total=Sum("capacity"),
        ):
            capacity = item["capacity_total"] or 1
            equipment_usage.append(
                {
                    "label": item["category"],
                    "value": round((item["booked_total"] or 0) / capacity * 100, 2),
                }
            )

        return Response(
            {
                "totals": {
                    "members": Profile.objects.filter(role=UserRole.MEMBER).count(),
                    "trainers": Profile.objects.filter(role=UserRole.TRAINER).count(),
                    "active_memberships": MembershipRecord.objects.filter(
                        status__iexact="Active",
                        expires_at__gt=timezone.now(),
                    ).count(),
                    "bookings_today": Booking.objects.filter(date=today).count(),
                    "revenue_7d": float(
                        confirmed_payments.filter(created_at__gte=start)
                        .aggregate(value=Sum("amount"))
                        .get("value")
                        or 0
                    ),
                },
                "revenue_trend": revenue_trend,
                "booking_trend": booking_trend,
                "equipment_usage": equipment_usage,
            }
        )


class ReportsAPIView(APIView):
    permission_classes = [IsAdminRole]

    def get(self, request):
        active_memberships = MembershipRecord.objects.filter(
            status__iexact="Active",
            expires_at__gt=timezone.now(),
        ).count()
        completed_sessions = Booking.objects.filter(status=BookingStatus.COMPLETED).count()
        capacity = EquipmentItem.objects.aggregate(value=Sum("capacity")).get("value") or 1
        booked = EquipmentItem.objects.aggregate(value=Sum("booked")).get("value") or 0
        revenue = (
            PaymentRecord.objects.filter(status=PaymentStatus.CONFIRMED)
            .aggregate(value=Sum("amount"))
            .get("value")
            or 0
        )

        rows = [
            {
                "title": "Daily revenue",
                "metric": f"KES {float(revenue):,.0f}",
                "change": "+0%",
                "status": "Ready",
            },
            {
                "title": "Trainer performance",
                "metric": f"{completed_sessions} sessions",
                "change": "+0%",
                "status": "Ready",
            },
            {
                "title": "Equipment usage",
                "metric": f"{round(booked / capacity * 100)}% utilization",
                "change": "+0%",
                "status": "Review",
            },
            {
                "title": "Membership growth",
                "metric": f"{active_memberships} active",
                "change": "+0%",
                "status": "Ready",
            },
        ]
        return Response(rows)


class ExportReportAPIView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        fmt = (request.GET.get("format") or "pdf").lower()
        export_type = (request.GET.get("type") or request.GET.get("report") or "dashboard").lower()
        rng = request.GET.get("range") or "Monthly"

        # build rows similar to ReportsAPIView or membership
        if export_type == "membership" or request.path.endswith("membership/"):
            # try to fetch membership for user, fallback to latest record
            membership = None
            try:
                if request.user and request.user.is_authenticated:
                    membership = (
                        MembershipRecord.objects.filter(user=request.user)
                        .order_by("-started_at")
                        .first()
                    )
            except Exception:
                membership = None

            if not membership:
                return JsonResponse({"detail": "No membership found"}, status=404)

            rows = [
                {"title": "Plan", "metric": membership.plan.name if hasattr(membership.plan, 'name') else str(membership.plan), "change": "", "status": membership.status},
                {"title": "Started", "metric": membership.started_at.isoformat(), "change": "", "status": membership.status},
                {"title": "Expires", "metric": membership.expires_at.isoformat(), "change": f"{(membership.expires_at - membership.started_at).days} days", "status": membership.status},
                {"title": "Payment", "metric": getattr(membership, 'payment_status', '') and str(membership.payment_status) or '', "change": getattr(membership, 'payment_due_at', None) and (membership.payment_due_at.isoformat()) or '', "status": membership.status},
            ]
            filename_base = f"membership_{membership.user.id if membership.user_id else 'anon'}"
        else:
            # admin/dashboard report
            active_memberships = MembershipRecord.objects.filter(
                status__iexact="Active",
                expires_at__gt=timezone.now(),
            ).count()
            completed_sessions = Booking.objects.filter(status=BookingStatus.COMPLETED).count()
            capacity = EquipmentItem.objects.aggregate(value=Sum("capacity")).get("value") or 1
            booked = EquipmentItem.objects.aggregate(value=Sum("booked")).get("value") or 0
            revenue = (
                PaymentRecord.objects.filter(status=PaymentStatus.CONFIRMED)
                .aggregate(value=Sum("amount"))
                .get("value")
                or 0
            )

            rows = [
                {"title": "Daily revenue", "metric": f"KES {float(revenue):,.0f}", "change": "+0%", "status": "Ready"},
                {"title": "Trainer performance", "metric": f"{completed_sessions} sessions", "change": "+0%", "status": "Ready"},
                {"title": "Equipment usage", "metric": f"{round(booked / capacity * 100)}% utilization", "change": "+0%", "status": "Review"},
                {"title": "Membership growth", "metric": f"{active_memberships} active", "change": "+0%", "status": "Ready"},
            ]
            filename_base = f"dashboard_report"

        # generate file
        if fmt == "pdf":
            buffer = BytesIO()
            if letter is None:
                return JsonResponse({"detail": "reportlab not installed on server"}, status=500)
            c = canvas.Canvas(buffer, pagesize=letter)
            x = 40
            y = 750
            c.setFont("Helvetica-Bold", 16)
            c.drawString(x, y, "Gym Booking Report")
            y -= 24
            c.setFont("Helvetica", 10)
            c.drawString(x, y, f"Range: {rng}")
            y -= 16
            c.drawString(x, y, f"Generated: {timezone.now().isoformat()}")
            y -= 24
            for row in rows:
                if y < 80:
                    c.showPage()
                    y = 750
                c.setFont("Helvetica-Bold", 11)
                c.drawString(x, y, row.get("title", ""))
                c.setFont("Helvetica", 10)
                c.drawString(x + 140, y, row.get("metric", ""))
                c.drawString(x + 320, y, row.get("change", ""))
                c.drawString(x + 420, y, row.get("status", ""))
                y -= 18
            c.showPage()
            c.save()
            buffer.seek(0)
            response = HttpResponse(buffer.getvalue(), content_type="application/pdf")
            response["Content-Disposition"] = f'attachment; filename="{filename_base}.pdf"'
            return response
        else:
            # xlsx
            if Workbook is None:
                return JsonResponse({"detail": "openpyxl not installed on server"}, status=500)
            wb = Workbook()
            ws = wb.active
            ws.title = "Report"
            ws.append(["Title", "Metric", "Change", "Status"])
            for row in rows:
                ws.append([row.get("title"), row.get("metric"), row.get("change"), row.get("status")])
            buffer = BytesIO()
            wb.save(buffer)
            buffer.seek(0)
            response = HttpResponse(buffer.getvalue(), content_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
            response["Content-Disposition"] = f'attachment; filename="{filename_base}.xlsx"'
            return response
