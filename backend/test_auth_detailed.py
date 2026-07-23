#!/usr/bin/env python
"""Detailed authentication diagnostics"""
import os
import sys
import django
from django.contrib.auth.hashers import make_password

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'fitflow_api.settings')
sys.path.insert(0, os.path.dirname(__file__))
django.setup()

from django.contrib.auth.models import User
from core.models import Profile, UserRole

print("=" * 80)
print("DETAILED AUTHENTICATION DIAGNOSTIC")
print("=" * 80)

# Test database password verification
print("\n[TEST] Direct Password Verification:")
print("-" * 80)

# Create a test user with known password
test_email = 'direct_test_user@test.com'
test_password = 'TestPassword123'

# Delete if already exists
User.objects.filter(email=test_email).delete()

test_user = User.objects.create_user(
    username=test_email,
    email=test_email,
    password=test_password,
    first_name='Direct Test'
)
# Profile created automatically via signals
print(f"Created test user: {test_email}")
print(f"Password set to: {test_password}")

# Verify password directly
if test_user.check_password(test_password):
    print("✓ Direct password check works")
else:
    print("✗ Direct password check FAILED")

# Check what's in the database
print(f"User password hash: {test_user.password[:50]}...")

# Test existing users
print("\n[TEST] Existing Users Password Status:")
print("-" * 80)
existing_users = User.objects.filter(email__in=['amina@example.com', 'admin@example.com'])
for user in existing_users:
    print(f"{user.email}:")
    print(f"  - Password hash exists: {bool(user.password)}")
    print(f"  - Has usable password: {user.has_usable_password()}")
    print(f"  - Staff: {user.is_staff}, Active: {user.is_active}")
    # Try some common passwords
    for pwd in ['password', 'Password123', 'Test123', '']:
        if user.check_password(pwd):
            print(f"  - Matches password: '{pwd}'")

# Check serializer
print("\n[TEST] EmailTokenObtainPairSerializer:")
print("-" * 80)
from core.serializers import EmailTokenObtainPairSerializer

serializer_data = {
    'email': test_email,
    'password': test_password
}
serializer = EmailTokenObtainPairSerializer(data=serializer_data)
if serializer.is_valid():
    print("✓ Serializer validation passed")
    tokens = serializer.validated_data
    print(f"Access token issued: {bool(tokens.get('access'))}")
    print(f"Refresh token issued: {bool(tokens.get('refresh'))}")
else:
    print("✗ Serializer validation failed")
    print(f"Errors: {serializer.errors}")

print("\n" + "=" * 80)
print("DIAGNOSTIC COMPLETE")
print("=" * 80)
