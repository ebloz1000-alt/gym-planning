import uuid

from django.conf import settings
from django.contrib.auth.models import User
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models
from django.utils import timezone


class UserRole(models.TextChoices):
    MEMBER = "member", "Member"
    TRAINER = "trainer", "Trainer"
    ADMIN = "admin", "Admin"


class EquipmentStatus(models.TextChoices):
    AVAILABLE = "available", "Available"
    FULL = "full", "Full"
    MAINTENANCE = "maintenance", "Maintenance"


class BookingStatus(models.TextChoices):
    PENDING = "pending", "Pending"
    CONFIRMED = "confirmed", "Confirmed"
    COMPLETED = "completed", "Completed"
    CANCELLED = "cancelled", "Cancelled"


class PaymentStatus(models.TextChoices):
    PENDING = "pending", "Pending"
    CONFIRMED = "confirmed", "Confirmed"
    FAILED = "failed", "Failed"
    EXPIRED = "expired", "Expired"
    PAY_LATER = "payLater", "Pay Later"


class NotificationType(models.TextChoices):
    BOOKING = "booking", "Booking"
    MEMBERSHIP = "membership", "Membership"
    PAYMENT = "payment", "Payment"
    TRAINER = "trainer", "Trainer"
    REMINDER = "reminder", "Reminder"


class Profile(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="profile",
    )
    phone = models.CharField(max_length=32, blank=True)
    role = models.CharField(
        max_length=16,
        choices=UserRole.choices,
        default=UserRole.MEMBER,
    )
    status = models.CharField(max_length=32, default="Active")
    avatar_label = models.CharField(max_length=8, blank=True)
    joined_at = models.DateTimeField(default=timezone.now)

    def save(self, *args, **kwargs):
        if not self.avatar_label:
            self.avatar_label = initials_for_name(self.user.get_full_name() or self.user.email)
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.user.get_full_name() or self.user.email} ({self.role})"


class MembershipPlan(models.Model):
    name = models.CharField(max_length=80, unique=True)
    duration_days = models.PositiveIntegerField()
    price = models.DecimalField(max_digits=10, decimal_places=2)
    features = models.JSONField(default=list, blank=True)
    highlight = models.BooleanField(default=False)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["price", "duration_days"]

    def __str__(self):
        return self.name


class MembershipRecord(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="memberships",
    )
    plan = models.ForeignKey(
        MembershipPlan,
        on_delete=models.PROTECT,
        related_name="memberships",
    )
    started_at = models.DateTimeField(default=timezone.now)
    expires_at = models.DateTimeField()
    status = models.CharField(max_length=32, default="Active")
    payment_status = models.CharField(
        max_length=16,
        choices=PaymentStatus.choices,
        default=PaymentStatus.CONFIRMED,
    )
    payment_due_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-started_at"]

    @property
    def is_bookable(self):
        now = timezone.now()
        payment_open = (
            self.payment_status == PaymentStatus.CONFIRMED
            or (
                self.payment_status == PaymentStatus.PAY_LATER
                and (self.payment_due_at is None or self.payment_due_at > now)
            )
        )
        return self.status.lower() == "active" and self.expires_at > now and payment_open

    @property
    def days_remaining(self):
        remaining = self.expires_at - timezone.now()
        if remaining.total_seconds() <= 0:
            return 0
        return max(1, remaining.days + (1 if remaining.seconds else 0))

    def __str__(self):
        return f"{self.user.email} - {self.plan.name}"


class EquipmentItem(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=120)
    category = models.CharField(max_length=60)
    capacity = models.PositiveIntegerField(default=1)
    booked = models.PositiveIntegerField(default=0)
    status = models.CharField(
        max_length=24,
        choices=EquipmentStatus.choices,
        default=EquipmentStatus.AVAILABLE,
    )
    location = models.CharField(max_length=120, blank=True)
    image_icon = models.CharField(max_length=80, blank=True)
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["category", "name"]

    @property
    def available(self):
        return max(self.capacity - self.booked, 0)

    def __str__(self):
        return self.name


class TrainerProfile(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="trainer_profile",
    )
    specialty = models.CharField(max_length=120)
    rating = models.DecimalField(max_digits=3, decimal_places=2, default=0)
    sessions_today = models.PositiveIntegerField(default=0)
    available_slots = models.JSONField(default=list, blank=True)
    bio = models.TextField(blank=True)
    status = models.CharField(max_length=32, default="Available")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["user__first_name"]

    def __str__(self):
        return self.user.get_full_name() or self.user.email


class Booking(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="bookings",
    )
    equipment = models.ForeignKey(
        EquipmentItem,
        on_delete=models.PROTECT,
        related_name="bookings",
    )
    trainer = models.ForeignKey(
        TrainerProfile,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="bookings",
    )
    date = models.DateField()
    time_slot = models.CharField(max_length=16)
    status = models.CharField(
        max_length=16,
        choices=BookingStatus.choices,
        default=BookingStatus.PENDING,
    )
    payment_status = models.CharField(
        max_length=16,
        choices=PaymentStatus.choices,
        default=PaymentStatus.PENDING,
    )
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-date", "time_slot"]
        indexes = [
            models.Index(fields=["date", "time_slot"]),
            models.Index(fields=["status"]),
        ]

    def __str__(self):
        return f"{self.equipment.name} on {self.date} at {self.time_slot}"


class PaymentRecord(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="payments",
    )
    booking = models.ForeignKey(
        Booking,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="payments",
    )
    membership = models.ForeignKey(
        MembershipRecord,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="payments",
    )
    method = models.CharField(max_length=80)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(
        max_length=16,
        choices=PaymentStatus.choices,
        default=PaymentStatus.PENDING,
    )
    reference = models.CharField(max_length=80, unique=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.reference} - {self.amount}"


class Notification(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notifications",
    )
    type = models.CharField(
        max_length=24,
        choices=NotificationType.choices,
        default=NotificationType.REMINDER,
    )
    title = models.CharField(max_length=120)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return self.title


class FeedbackEntry(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="feedback_entries",
    )
    target = models.CharField(max_length=120)
    rating = models.PositiveSmallIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    comment = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name_plural = "feedback entries"

    def __str__(self):
        return f"{self.target} - {self.rating}/5"


def initials_for_name(name):
    parts = [part for part in name.strip().split() if part]
    if not parts:
        return "FF"
    if len(parts) == 1:
        return parts[0][:2].upper()
    return f"{parts[0][0]}{parts[-1][0]}".upper()
