#!/usr/bin/env python
"""Test script to diagnose authentication issues"""
import os
import sys
import django

# Configure Django settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'fitflow_api.settings')
sys.path.insert(0, os.path.dirname(__file__))
django.setup()

from django.contrib.auth.models import User
from core.models import Profile, UserRole
from rest_framework.test import APIClient
from rest_framework import status

client = APIClient()
api_base = 'http://localhost:8000/api'

print("=" * 80)
print("GYM BOOKING SYSTEM - AUTHENTICATION DIAGNOSTICS")
print("=" * 80)

# Test 1: Check existing users
print("\n[TEST 1] Existing Users in Database:")
print("-" * 80)
users = User.objects.all()
print(f"Total users: {users.count()}")
for user in users:
    profile = getattr(user, 'profile', None)
    role = profile.role if profile else 'No profile'
    print(f"  - {user.email} (Role: {role}, Staff: {user.is_staff}, Active: {user.is_active})")

# Test 2: Test Member Registration
print("\n[TEST 2] Member Registration:")
print("-" * 80)
new_email = f"testmember{User.objects.count()}@test.com"
register_data = {
    'name': 'Test Member',
    'email': new_email,
    'phone': '+254700000001',
    'password': 'TestPass123!@#'
}
print(f"Attempting registration with: {register_data}")
response = client.post(f'{api_base}/auth/register/', register_data, format='json')
print(f"Status Code: {response.status_code}")
print(f"Response: {response.json()}")

if response.status_code == 201:
    print("✓ MEMBER REGISTRATION WORKS")
else:
    print("✗ MEMBER REGISTRATION FAILED")

# Test 3: Test Member Login
print("\n[TEST 3] Member Login:")
print("-" * 80)
login_data = {
    'email': 'testmember@test.com',
    'password': 'TestPass123'
}
print(f"Attempting login with: {login_data}")
response = client.post(f'{api_base}/auth/token/', login_data, format='json')
print(f"Status Code: {response.status_code}")
print(f"Response: {response.json()}")

if response.status_code == 200:
    print("✓ MEMBER LOGIN WORKS")
    token = response.json().get('access')
    if token:
        client.defaults['HTTP_AUTHORIZATION'] = f'Bearer {token}'
        # Test /me endpoint
        me_response = client.get(f'{api_base}/auth/me/', format='json')
        print(f"Profile fetch status: {me_response.status_code}")
        print(f"Profile: {me_response.json()}")
else:
    print("✗ MEMBER LOGIN FAILED")

# Test 4: Check Trainer Account
print("\n[TEST 4] Trainer Login:")
print("-" * 80)
trainers = User.objects.filter(profile__role=UserRole.TRAINER)
print(f"Existing trainers: {trainers.count()}")
if trainers.exists():
    trainer = trainers.first()
    print(f"Trainer email: {trainer.email}")
    trainer_login_data = {
        'email': trainer.email,
        'password': 'TestPass123'  # Try default password
    }
    print(f"Attempting trainer login with: {trainer_login_data}")
    response = client.post(f'{api_base}/auth/token/', trainer_login_data, format='json')
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.json()}")
else:
    print("No trainers found in database")

# Test 5: Check Admin Account
print("\n[TEST 5] Admin Login:")
print("-" * 80)
admins = User.objects.filter(profile__role=UserRole.ADMIN)
print(f"Existing admins: {admins.count()}")
if admins.exists():
    admin = admins.first()
    print(f"Admin email: {admin.email}")
    print(f"Admin staff status: {admin.is_staff}")
    admin_login_data = {
        'email': admin.email,
        'password': 'TestPass123'
    }
    print(f"Attempting admin login with: {admin_login_data}")
    response = client.post(f'{api_base}/auth/token/', admin_login_data, format='json')
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.json()}")
else:
    print("No admins found in database")

# Test 6: Health check
print("\n[TEST 6] Health Check:")
print("-" * 80)
response = client.get(f'{api_base}/health/', format='json')
print(f"Status Code: {response.status_code}")
print(f"Response: {response.json()}")

print("\n" + "=" * 80)
print("DIAGNOSTICS COMPLETE")
print("=" * 80)
