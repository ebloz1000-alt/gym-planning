import uuid
from datetime import timedelta

from django.contrib.auth.models import User
from django.utils import timezone
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.tokens import RefreshToken

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
    initials_for_name,
)


class UserSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source="first_name")
    phone = serializers.CharField(source="profile.phone", required=False, allow_blank=True)
    role = serializers.ChoiceField(
        source="profile.role",
        choices=UserRole.choices,
        required=False,
    )
    status = serializers.CharField(source="profile.status", required=False)
    avatar_label = serializers.CharField(source="profile.avatar_label", read_only=True)
    joined_at = serializers.DateTimeField(source="profile.joined_at", read_only=True)

    class Meta:
        model = User
        fields = [
            "id",
            "name",
            "email",
            "phone",
            "role",
            "status",
            "avatar_label",
            "joined_at",
            "is_staff",
            "is_active",
        ]
        read_only_fields = ["id", "is_staff", "is_active"]

    def validate_email(self, value):
        value = value.lower().strip()
        queryset = User.objects.filter(email__iexact=value)
        if self.instance:
            queryset = queryset.exclude(id=self.instance.id)
        if queryset.exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value

    def update(self, instance, validated_data):
        profile_data = validated_data.pop("profile", {})
        request = self.context.get("request")
        requester_profile = getattr(getattr(request, "user", None), "profile", None)
        can_manage_roles = bool(
            request
            and request.user.is_authenticated
            and (request.user.is_staff or getattr(requester_profile, "role", "") == UserRole.ADMIN)
        )
        if not can_manage_roles:
            profile_data.pop("role", None)
            profile_data.pop("status", None)

        instance.first_name = validated_data.get("first_name", instance.first_name)
        instance.email = validated_data.get("email", instance.email)
        instance.username = instance.email
        instance.save()

        profile, _created = Profile.objects.get_or_create(user=instance)
        for field, value in profile_data.items():
            setattr(profile, field, value)
        profile.avatar_label = initials_for_name(instance.get_full_name() or instance.email)
        profile.save()
        return instance


class RegisterSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    phone = serializers.CharField(max_length=32, required=False, allow_blank=True)
    password = serializers.CharField(write_only=True, min_length=8)
    plan_id = serializers.PrimaryKeyRelatedField(
        queryset=MembershipPlan.objects.filter(active=True),
        required=False,
        allow_null=True,
    )
    duration_days = serializers.IntegerField(required=False, min_value=1)

    def validate_email(self, value):
        value = value.lower().strip()
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value

    def create(self, validated_data):
        name = validated_data["name"].strip()
        email = validated_data["email"]
        user = User.objects.create_user(
            username=email,
            email=email,
            password=validated_data["password"],
            first_name=name,
        )
        Profile.objects.update_or_create(
            user=user,
            defaults={
                "phone": validated_data.get("phone", ""),
                "role": UserRole.MEMBER,
                "status": "Active",
                "avatar_label": initials_for_name(name),
            },
        )

        plan = validated_data.get("plan_id")
        if plan is not None:
            started_at = timezone.now()
            duration = int(validated_data.get("duration_days") or plan.duration_days)
            MembershipRecord.objects.create(
                user=user,
                plan=plan,
                started_at=started_at,
                expires_at=started_at + timedelta(days=duration),
                status="Pending",
                payment_status=PaymentStatus.PENDING,
            )

        return user

    def to_representation(self, instance):
        refresh = RefreshToken.for_user(instance)
        return {
            "user": UserSerializer(instance).data,
            "refresh": str(refresh),
            "access": str(refresh.access_token),
        }


class EmailTokenObtainPairSerializer(TokenObtainPairSerializer):
    email = serializers.EmailField(required=False, write_only=True)

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields[self.username_field].required = False

    def validate(self, attrs):
        email = attrs.get("email")
        if email and not attrs.get(self.username_field):
            attrs[self.username_field] = email.lower().strip()
        return super().validate(attrs)


class MembershipPlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = MembershipPlan
        fields = [
            "id",
            "name",
            "duration_days",
            "price",
            "features",
            "highlight",
            "active",
        ]


class MembershipRecordSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source="user.first_name", read_only=True)
    plan = serializers.CharField(source="plan.name", read_only=True)
    plan_id = serializers.PrimaryKeyRelatedField(
        source="plan",
        queryset=MembershipPlan.objects.all(),
        write_only=True,
    )
    is_bookable = serializers.BooleanField(read_only=True)
    days_remaining = serializers.IntegerField(read_only=True)

    class Meta:
        model = MembershipRecord
        fields = [
            "id",
            "user",
            "user_name",
            "plan",
            "plan_id",
            "started_at",
            "expires_at",
            "status",
            "payment_status",
            "payment_due_at",
            "is_bookable",
            "days_remaining",
        ]
        read_only_fields = ["id", "user"]


class EquipmentItemSerializer(serializers.ModelSerializer):
    available = serializers.IntegerField(read_only=True)

    class Meta:
        model = EquipmentItem
        fields = [
            "id",
            "name",
            "category",
            "capacity",
            "booked",
            "available",
            "status",
            "location",
            "image_icon",
            "description",
        ]

    def validate(self, attrs):
        capacity = attrs.get("capacity", getattr(self.instance, "capacity", 0))
        booked = attrs.get("booked", getattr(self.instance, "booked", 0))
        if booked > capacity:
            raise serializers.ValidationError("Booked count cannot exceed capacity.")
        return attrs


class TrainerProfileSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source="user.first_name", read_only=True)
    email = serializers.EmailField(source="user.email", read_only=True)
    user_id = serializers.PrimaryKeyRelatedField(
        source="user",
        queryset=User.objects.all(),
        write_only=True,
    )

    class Meta:
        model = TrainerProfile
        fields = [
            "id",
            "user_id",
            "name",
            "email",
            "specialty",
            "rating",
            "sessions_today",
            "available_slots",
            "bio",
            "status",
        ]


class BookingSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source="user.first_name", read_only=True)
    equipment_name = serializers.CharField(source="equipment.name", read_only=True)
    trainer_name = serializers.CharField(source="trainer.user.first_name", read_only=True)
    equipment_id = serializers.PrimaryKeyRelatedField(
        source="equipment",
        queryset=EquipmentItem.objects.all(),
        write_only=True,
    )
    trainer_id = serializers.PrimaryKeyRelatedField(
        source="trainer",
        queryset=TrainerProfile.objects.all(),
        required=False,
        allow_null=True,
        write_only=True,
    )

    class Meta:
        model = Booking
        fields = [
            "id",
            "user",
            "user_name",
            "equipment_id",
            "equipment_name",
            "trainer_id",
            "trainer_name",
            "date",
            "time_slot",
            "status",
            "payment_status",
            "notes",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "user", "created_at", "updated_at"]

    def validate(self, attrs):
        equipment = attrs.get("equipment", getattr(self.instance, "equipment", None))
        if equipment and equipment.status == "maintenance":
            raise serializers.ValidationError("This equipment is under maintenance.")
        return attrs


class PaymentRecordSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source="user.first_name", read_only=True)
    reference = serializers.CharField(required=False, allow_blank=True)
    booking_id = serializers.PrimaryKeyRelatedField(
        source="booking",
        queryset=Booking.objects.all(),
        required=False,
        allow_null=True,
    )
    membership_id = serializers.PrimaryKeyRelatedField(
        source="membership",
        queryset=MembershipRecord.objects.all(),
        required=False,
        allow_null=True,
    )

    class Meta:
        model = PaymentRecord
        fields = [
            "id",
            "user",
            "user_name",
            "booking_id",
            "membership_id",
            "method",
            "amount",
            "status",
            "reference",
            "metadata",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "user", "created_at", "updated_at"]

    def validate_reference(self, value):
        if self.instance and self.instance.reference == value:
            return value
        if PaymentRecord.objects.filter(reference=value).exists():
            raise serializers.ValidationError("Payment reference already exists.")
        return value


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = [
            "id",
            "user",
            "type",
            "title",
            "message",
            "is_read",
            "created_at",
        ]
        read_only_fields = ["id", "user", "created_at"]


class FeedbackEntrySerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source="user.first_name", read_only=True)

    class Meta:
        model = FeedbackEntry
        fields = [
            "id",
            "user",
            "user_name",
            "target",
            "rating",
            "comment",
            "created_at",
        ]
        read_only_fields = ["id", "user", "created_at"]


class RenewMembershipSerializer(serializers.Serializer):
    plan_id = serializers.PrimaryKeyRelatedField(queryset=MembershipPlan.objects.filter(active=True))
    duration_days = serializers.IntegerField(required=False, min_value=1)
    amount = serializers.DecimalField(max_digits=10, decimal_places=2)
    payment_status = serializers.ChoiceField(
        choices=PaymentStatus.choices,
        default=PaymentStatus.CONFIRMED,
    )
    payment_due_at = serializers.DateTimeField(required=False, allow_null=True)

    def _default_payment_due_at(self):
        now = timezone.now()
        due_at = now.replace(hour=12, minute=0, second=0, microsecond=0)
        if due_at <= now:
            due_at = due_at + timedelta(days=1)
        return due_at

    def save(self, **kwargs):
        user = self.context["request"].user
        plan = self.validated_data["plan_id"]
        duration_days = int(self.validated_data.get("duration_days") or plan.duration_days)
        amount = self.validated_data["amount"]
        payment_status = self.validated_data["payment_status"]
        payment_due_at = self.validated_data.get("payment_due_at")
        if payment_status == PaymentStatus.PAY_LATER and payment_due_at is None:
            payment_due_at = self._default_payment_due_at()

        started_at = timezone.now()
        if payment_status == PaymentStatus.PAY_LATER:
            method = "Pay Later"
            record_status = "Active"
            payment_status_for_record = PaymentStatus.PENDING
        elif payment_status == PaymentStatus.PENDING:
            method = "Cash"
            record_status = "Pending"
            payment_status_for_record = PaymentStatus.PENDING
        else:
            method = "M-Pesa STK"
            record_status = "Active"
            payment_status_for_record = payment_status

        record = MembershipRecord.objects.create(
            user=user,
            plan=plan,
            started_at=started_at,
            expires_at=started_at + timedelta(days=duration_days),
            status=record_status,
            payment_status=payment_status,
            payment_due_at=payment_due_at,
        )

        PaymentRecord.objects.create(
            user=user,
            membership=record,
            method=method,
            amount=amount,
            status=payment_status_for_record,
            reference=f"MEM-{uuid.uuid4().hex[:10].upper()}",
        )
        return record
