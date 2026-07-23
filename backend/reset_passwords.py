#!/usr/bin/env python
"""Reset user passwords for testing"""
import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'fitflow_api.settings')
sys.path.insert(0, os.path.dirname(__file__))
django.setup()

from django.contrib.auth.models import User

default_password = "Password123!@#"

print("=" * 80)
print("RESETTING USER PASSWORDS FOR TESTING")
print("=" * 80)

users = User.objects.all()
for user in users:
    user.set_password(default_password)
    user.save()
    print(f"✓ Reset password for {user.email} to '{default_password}'")

print("=" * 80)
print(f"Total users updated: {users.count()}")
print("=" * 80)
