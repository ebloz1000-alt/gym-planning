from django.contrib import admin

from core.models import (
    Booking,
    EquipmentItem,
    FeedbackEntry,
    MembershipPlan,
    MembershipRecord,
    Notification,
    PaymentRecord,
    Profile,
    TrainerProfile,
)


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ("user", "role", "status", "phone", "joined_at")
    list_filter = ("role", "status")
    search_fields = ("user__email", "user__first_name", "phone")


@admin.register(MembershipPlan)
class MembershipPlanAdmin(admin.ModelAdmin):
    list_display = ("name", "duration_days", "price", "highlight", "active")
    list_filter = ("active", "highlight")
    search_fields = ("name",)


@admin.register(MembershipRecord)
class MembershipRecordAdmin(admin.ModelAdmin):
    list_display = ("user", "plan", "status", "payment_status", "started_at", "expires_at")
    list_filter = ("status", "payment_status", "plan")
    search_fields = ("user__email", "user__first_name", "plan__name")


@admin.register(EquipmentItem)
class EquipmentItemAdmin(admin.ModelAdmin):
    list_display = ("name", "category", "capacity", "booked", "status", "location")
    list_filter = ("category", "status")
    search_fields = ("name", "location")


@admin.register(TrainerProfile)
class TrainerProfileAdmin(admin.ModelAdmin):
    list_display = ("user", "specialty", "rating", "sessions_today", "status")
    list_filter = ("status", "specialty")
    search_fields = ("user__email", "user__first_name", "specialty")


@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = ("user", "equipment", "trainer", "date", "time_slot", "status", "payment_status")
    list_filter = ("status", "payment_status", "date")
    search_fields = ("user__email", "equipment__name", "trainer__user__first_name")


@admin.register(PaymentRecord)
class PaymentRecordAdmin(admin.ModelAdmin):
    list_display = ("reference", "user", "method", "amount", "status", "created_at")
    list_filter = ("status", "method")
    search_fields = ("reference", "user__email")


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ("title", "user", "type", "is_read", "created_at")
    list_filter = ("type", "is_read")
    search_fields = ("title", "user__email")


@admin.register(FeedbackEntry)
class FeedbackEntryAdmin(admin.ModelAdmin):
    list_display = ("target", "rating", "user", "created_at")
    list_filter = ("rating",)
    search_fields = ("target", "comment", "user__email")
