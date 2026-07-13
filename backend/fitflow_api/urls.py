from django.contrib import admin
from django.urls import include, path
from rest_framework_simplejwt.views import TokenRefreshView

from core.views import EmailTokenObtainPairView, HealthAPIView, MeAPIView, RegisterAPIView


urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/health/", HealthAPIView.as_view(), name="health"),
    path("api/auth/register/", RegisterAPIView.as_view(), name="register"),
    path("api/auth/me/", MeAPIView.as_view(), name="me"),
    path("api/auth/token/", EmailTokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("api/auth/token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("api/", include("core.urls")),
]
