# GYM BOOKING SYSTEM - AUTHENTICATION FIXES

## Issues Fixed

### 1. ✓ Database Configuration
**Problem**: Backend was trying to connect to PostgreSQL (Neon DB) with invalid credentials
**Solution**: Changed `.env` to use SQLite for local development by commenting out `DATABASE_URL`
**Files Modified**: `.env`

### 2. ✓ ALLOWED_HOSTS Configuration  
**Problem**: Test client and requests to 'testserver' were rejected
**Solution**: Added 'testserver' to ALLOWED_HOSTS in both settings.py and .env
**Files Modified**: `fitflow_api/settings.py`, `.env`

### 3. ✓ User Password Reset
**Problem**: Existing test users (amina@example.com, admin@example.com, trainers, etc.) had unknown passwords
**Solution**: Reset all user passwords to: `Password123!@#`
**Command**: `python reset_passwords.py`
**Users Updated**: 9 users

### 4. ✓ JWT Secret Key
**Problem**: InsecureKeyLengthWarning about SHORT SECRET_KEY (26 bytes instead of 32+ bytes)
**Solution**: Generated new secure SECRET_KEY using Django's get_random_secret_key()
**Files Modified**: `.env` (SECRET_KEY updated)

## Authentication Test Results ✓

All authentication flows now work correctly:

```
✓ Member Registration - Status 201
✓ Member Login - Status 200
✓ Member Profile Fetch - Status 200  
✓ Trainer Login - Status 200
✓ Admin Login - Status 200
✓ JWT Token Refresh - Status 200
```

## Test Credentials

Use these credentials for testing:

| Role    | Email                      | Password       |
|---------|----------------------------|----------------|
| Member  | amina@example.com          | Password123!@# |
| Member  | kevin@example.com          | Password123!@# |
| Trainer | brian.trainer@example.com  | Password123!@# |
| Trainer | maya.trainer@example.com   | Password123!@# |
| Trainer | leo.trainer@example.com    | Password123!@# |
| Admin   | admin@example.com          | Password123!@# |

Or register a new member account at the registration endpoint.

## How to Run Tests

### Backend Setup
```bash
cd backend
.\.venv\Scripts\Activate.ps1
python manage.py migrate
python reset_passwords.py  # To reset user passwords if needed
```

### Run Full Authentication Tests
```bash
cd backend
.\.venv\Scripts\Activate.ps1
python test_auth_full.py
```

### Start Development Server
```bash
cd backend
.\.venv\Scripts\Activate.ps1
python manage.py runserver 0.0.0.0:8000
```

## API Endpoints

### Authentication Endpoints
- `POST /api/auth/register/` - Register new member
- `POST /api/auth/token/` - Login (get JWT tokens)
- `POST /api/auth/token/refresh/` - Refresh JWT access token
- `GET /api/auth/me/` - Get current user profile

### Example Requests

**Register:**
```json
POST /api/auth/register/
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+254700000000",
  "password": "SecurePass123!@#"
}
```

**Login:**
```json
POST /api/auth/token/
{
  "email": "john@example.com",
  "password": "SecurePass123!@#"
}
Response:
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Get Profile (with Authorization header):**
```
GET /api/auth/me/
Authorization: Bearer <access_token>
```

## Flutter Frontend Configuration

The Flutter app is already configured to connect to:
- **Web/Desktop**: `http://localhost:8000`
- **Android Emulator**: `http://10.0.2.2:8000`

Test credentials can be used directly in the Flutter auth screen.

## Next Steps

1. ✓ Start backend server: `python manage.py runserver`
2. ✓ Test with provided credentials
3. ✓ Test member registration in Flutter app
4. ✓ Test trainer and admin login screens
5. ✓ Verify all dashboard features work after login

All authentication issues have been resolved!
