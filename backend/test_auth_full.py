#!/usr/bin/env python
"""Test script to verify all authentication flows work"""
import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'fitflow_api.settings')
sys.path.insert(0, os.path.dirname(__file__))
django.setup()

from django.contrib.auth.models import User
from core.models import UserRole
from rest_framework.test import APIClient
from rest_framework import status

client = APIClient()
api_base = 'http://testserver/api'
test_password = 'Password123!@#'

print("=" * 80)
print("GYM BOOKING SYSTEM - FULL AUTH TEST")
print("=" * 80)

# Test 1: Member Registration
print("\n[TEST 1] Member Registration:")
print("-" * 80)
new_email = f"newmember{User.objects.count()}@test.com"
register_data = {
    'name': 'New Member Account',
    'email': new_email,
    'phone': '+254700000099',
    'password': test_password
}
print(f"Registering: {new_email}")
response = client.post(f'{api_base}/auth/register/', register_data, format='json')
print(f"Status: {response.status_code}")
if response.status_code == 201:
    print("✓ MEMBER REGISTRATION WORKS")
    resp_data = response.json()
    print(f"  User created: {resp_data.get('user', {}).get('email')}")
    print(f"  Role: {resp_data.get('user', {}).get('role')}")
else:
    print(f"✗ Registration failed: {response.json()}")

# Test 2: Member Login
print("\n[TEST 2] Member Login:")
print("-" * 80)
member_email = 'amina@example.com'
login_data = {'email': member_email, 'password': test_password}
print(f"Logging in: {member_email}")
response = client.post(f'{api_base}/auth/token/', login_data, format='json')
print(f"Status: {response.status_code}")
if response.status_code == 200:
    print("✓ MEMBER LOGIN WORKS")
    resp_data = response.json()
    token = resp_data.get('access')
    print(f"  Access token issued: {bool(token)}")
    if token:
        client.defaults['HTTP_AUTHORIZATION'] = f'Bearer {token}'
        me_response = client.get(f'{api_base}/auth/me/', format='json')
        if me_response.status_code == 200:
            profile = me_response.json()
            print(f"  Profile retrieved: {profile.get('email')}")
            print(f"  Name: {profile.get('name')}")
            print(f"  Role: {profile.get('role')}")
        else:
            print(f"  Profile fetch failed: {me_response.status_code}")
else:
    print(f"✗ Login failed: {response.json()}")

# Test 3: Trainer Login
print("\n[TEST 3] Trainer Login:")
print("-" * 80)
trainer_email = 'brian.trainer@example.com'
login_data = {'email': trainer_email, 'password': test_password}
print(f"Logging in: {trainer_email}")
response = client.post(f'{api_base}/auth/token/', login_data, format='json')
print(f"Status: {response.status_code}")
if response.status_code == 200:
    print("✓ TRAINER LOGIN WORKS")
    resp_data = response.json()
    token = resp_data.get('access')
    print(f"  Access token issued: {bool(token)}")
    if token:
        client.defaults['HTTP_AUTHORIZATION'] = f'Bearer {token}'
        me_response = client.get(f'{api_base}/auth/me/', format='json')
        if me_response.status_code == 200:
            profile = me_response.json()
            print(f"  Profile retrieved: {profile.get('email')}")
            print(f"  Role: {profile.get('role')}")
else:
    print(f"✗ Login failed: {response.json()}")

# Test 4: Admin Login
print("\n[TEST 4] Admin Login:")
print("-" * 80)
admin_email = 'admin@example.com'
login_data = {'email': admin_email, 'password': test_password}
print(f"Logging in: {admin_email}")
response = client.post(f'{api_base}/auth/token/', login_data, format='json')
print(f"Status: {response.status_code}")
if response.status_code == 200:
    print("✓ ADMIN LOGIN WORKS")
    resp_data = response.json()
    token = resp_data.get('access')
    print(f"  Access token issued: {bool(token)}")
    if token:
        client.defaults['HTTP_AUTHORIZATION'] = f'Bearer {token}'
        me_response = client.get(f'{api_base}/auth/me/', format='json')
        if me_response.status_code == 200:
            profile = me_response.json()
            print(f"  Profile retrieved: {profile.get('email')}")
            print(f"  Role: {profile.get('role')}")
            print(f"  Is staff: {profile.get('is_staff')}")
else:
    print(f"✗ Login failed: {response.json()}")

# Test 5: JWT Refresh
print("\n[TEST 5] JWT Token Refresh:")
print("-" * 80)
login_data = {'email': member_email, 'password': test_password}
response = client.post(f'{api_base}/auth/token/', login_data, format='json')
if response.status_code == 200:
    refresh_token = response.json().get('refresh')
    refresh_data = {'refresh': refresh_token}
    response = client.post(f'{api_base}/auth/token/refresh/', refresh_data, format='json')
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        print("✓ TOKEN REFRESH WORKS")
        print(f"  New access token issued: {bool(response.json().get('access'))}")
    else:
        print(f"✗ Refresh failed: {response.json()}")
else:
    print("✗ Initial login failed for refresh test")

print("\n" + "=" * 80)
print("AUTH TEST COMPLETE")
print("=" * 80)
