from django.urls import path
from rest_framework.routers import DefaultRouter

from core.views import (
    AnalyticsAPIView,
    BookingViewSet,
    EquipmentItemViewSet,
    FeedbackEntryViewSet,
    MembershipPlanViewSet,
    MembershipRecordViewSet,
    NotificationViewSet,
    PaymentRecordViewSet,
    ReportsAPIView,
    TrainerProfileViewSet,
    UserViewSet,
)


router = DefaultRouter()
router.register("users", UserViewSet, basename="user")
router.register("membership-plans", MembershipPlanViewSet, basename="membership-plan")
router.register("memberships", MembershipRecordViewSet, basename="membership")
router.register("equipment", EquipmentItemViewSet, basename="equipment")
router.register("trainers", TrainerProfileViewSet, basename="trainer")
router.register("bookings", BookingViewSet, basename="booking")
router.register("payments", PaymentRecordViewSet, basename="payment")
router.register("notifications", NotificationViewSet, basename="notification")
router.register("feedback", FeedbackEntryViewSet, basename="feedback")

urlpatterns = [
    path("analytics/", AnalyticsAPIView.as_view(), name="analytics"),
    path("reports/", ReportsAPIView.as_view(), name="reports"),
]

urlpatterns += router.urls
