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
