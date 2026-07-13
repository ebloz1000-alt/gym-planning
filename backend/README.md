# FitFlow Gym Backend

Django REST Framework API for the gym booking Flutter app.

## Local setup

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
python manage.py migrate
python manage.py seed_demo
python manage.py runserver
```

The API will be available at `http://127.0.0.1:8000/api/`.

## Main endpoints

- `GET /api/health/`
- `POST /api/auth/register/`
- `POST /api/auth/token/`
- `POST /api/auth/token/refresh/`
- `GET/PATCH /api/auth/me/`
- `/api/users/`
- `/api/membership-plans/`
- `/api/memberships/`
- `/api/memberships/renew/`
- `/api/equipment/`
- `/api/trainers/`
- `/api/bookings/`
- `/api/payments/`
- `/api/notifications/`
- `/api/feedback/`
- `GET /api/analytics/`
- `GET /api/reports/`

Demo accounts after `seed_demo`:

- `amina@example.com` / `password123`
- `brian.trainer@example.com` / `password123`
- `admin@example.com` / `password123`

## Render deployment

Create a Render Web Service with:

- Root Directory: `backend`
- Build Command: `pip install -r requirements.txt && python manage.py collectstatic --noinput && python manage.py migrate`
- Start Command: `gunicorn fitflow_api.wsgi:application`

Environment variables:

```env
SECRET_KEY=<strong random key>
DEBUG=False
ALLOWED_HOSTS=<your-render-service>.onrender.com
CSRF_TRUSTED_ORIGINS=https://<your-render-service>.onrender.com
CORS_ALLOWED_ORIGINS=https://<your-frontend-domain>
DATABASE_URL=<Neon pooled connection string>
DARAJA_CONSUMER_KEY=<optional>
DARAJA_CONSUMER_SECRET=<optional>
```

After deploy, open a Render shell and run:

```bash
python manage.py seed_demo
python manage.py createsuperuser
```
