from datetime import timedelta

from django.contrib.auth.models import User
from django.core.management.base import BaseCommand
from django.utils import timezone

from core.models import (
    Booking,
    BookingStatus,
    EquipmentItem,
    EquipmentStatus,
    FeedbackEntry,
    MembershipPlan,
    MembershipRecord,
    Notification,
    NotificationType,
    PaymentRecord,
    PaymentStatus,
    Profile,
    TrainerProfile,
    UserRole,
    initials_for_name,
)


class Command(BaseCommand):
    help = "Seed demo gym data that matches the Flutter mock repository."

    def add_arguments(self, parser):
        parser.add_argument(
            "--reset",
            action="store_true",
            help="Delete demo data before seeding it again.",
        )

    def handle(self, *args, **options):
        if options["reset"]:
            self.reset_demo_data()

        users = self.seed_users()
        plans = self.seed_membership_plans()
        equipment = self.seed_equipment()
        trainers = self.seed_trainers(users)
        self.seed_memberships(users, plans)
        self.seed_bookings(users, equipment, trainers)
        self.seed_payments(users)
        self.seed_notifications(users)
        self.seed_feedback(users)

        self.stdout.write(self.style.SUCCESS("Demo data seeded."))

    def reset_demo_data(self):
        FeedbackEntry.objects.all().delete()
        Notification.objects.all().delete()
        PaymentRecord.objects.all().delete()
        Booking.objects.all().delete()
        MembershipRecord.objects.all().delete()
        TrainerProfile.objects.all().delete()
        EquipmentItem.objects.all().delete()
        MembershipPlan.objects.all().delete()
        User.objects.filter(
            email__in=[
                "amina@example.com",
                "brian.trainer@example.com",
                "admin@example.com",
                "kevin@example.com",
                "maya.trainer@example.com",
                "leo.trainer@example.com",
            ]
        ).delete()

    def seed_users(self):
        data = [
            ("Amina Otieno", "amina@example.com", "+254 711 245 901", UserRole.MEMBER, False, False),
            ("Brian Kariuki", "brian.trainer@example.com", "+254 712 883 220", UserRole.TRAINER, False, False),
            ("Grace Admin", "admin@example.com", "+254 733 101 303", UserRole.ADMIN, True, True),
            ("Kevin Njoroge", "kevin@example.com", "+254 722 013 444", UserRole.MEMBER, False, False),
            ("Maya Wanjiku", "maya.trainer@example.com", "+254 700 999 201", UserRole.TRAINER, False, False),
            ("Leo Mutua", "leo.trainer@example.com", "+254 700 700 202", UserRole.TRAINER, False, False),
        ]
        users = {}
        for name, email, phone, role, is_staff, is_superuser in data:
            user, created = User.objects.get_or_create(
                username=email,
                defaults={
                    "email": email,
                    "first_name": name,
                    "is_staff": is_staff,
                    "is_superuser": is_superuser,
                },
            )
            if created:
                user.set_password("password123")
            user.email = email
            user.first_name = name
            user.is_staff = is_staff
            user.is_superuser = is_superuser
            user.save()
            Profile.objects.update_or_create(
                user=user,
                defaults={
                    "phone": phone,
                    "role": role,
                    "status": "Suspended" if email == "kevin@example.com" else "Active",
                    "avatar_label": initials_for_name(name),
                },
            )
            users[email] = user
        return users

    def seed_membership_plans(self):
        data = [
            ("Daily", 1, 400, False, ["Single day access", "Equipment booking", "Pay Later until 12:00 PM"]),
            ("Weekly", 7, 2200, False, ["7-day access", "2 trainer sessions", "Booking priority"]),
            ("Monthly", 30, 6800, True, ["Unlimited access", "8 trainer sessions", "Progress review"]),
            ("VIP", 45, 12000, False, ["Flexible duration", "Premium trainer slots", "VIP support"]),
        ]
        plans = {}
        for name, duration_days, price, highlight, features in data:
            plan, _created = MembershipPlan.objects.update_or_create(
                name=name,
                defaults={
                    "duration_days": duration_days,
                    "price": price,
                    "highlight": highlight,
                    "features": features,
                    "active": True,
                },
            )
            plans[name] = plan
        return plans

    def seed_equipment(self):
        data = [
            ("Treadmill Pro X", "Cardio", 10, 6, EquipmentStatus.AVAILABLE, "Cardio Zone A", "directions_run_outlined", "High-incline treadmill with heart rate monitoring."),
            ("Olympic Bench Press", "Strength", 4, 4, EquipmentStatus.FULL, "Strength Bay 2", "fitness_center_outlined", "Adjustable bench setup for barbell strength programs."),
            ("Cable Crossover", "Functional", 6, 2, EquipmentStatus.AVAILABLE, "Functional Studio", "cable_outlined", "Dual-pulley station for guided movement training."),
            ("Spin Bike Row", "Cardio", 16, 11, EquipmentStatus.AVAILABLE, "Studio B", "pedal_bike_outlined", "Group cycling bikes with resistance calibration."),
            ("Assault AirBike", "Cardio", 3, 0, EquipmentStatus.MAINTENANCE, "Maintenance Hold", "air_outlined", "Full-body conditioning bikes undergoing service."),
            ("Recovery Boots", "Recovery", 5, 1, EquipmentStatus.AVAILABLE, "Recovery Lounge", "self_improvement_outlined", "Compression recovery equipment for post-session care."),
        ]
        equipment = {}
        for name, category, capacity, booked, status, location, image_icon, description in data:
            item, _created = EquipmentItem.objects.update_or_create(
                name=name,
                defaults={
                    "category": category,
                    "capacity": capacity,
                    "booked": booked,
                    "status": status,
                    "location": location,
                    "image_icon": image_icon,
                    "description": description,
                },
            )
            equipment[name] = item
        return equipment

    def seed_trainers(self, users):
        data = [
            ("brian.trainer@example.com", "Strength & Hypertrophy", 4.9, 5, ["07:00", "12:00", "18:00"], "Available", "Structured strength coaching with technique audits and progression."),
            ("maya.trainer@example.com", "Cardio Conditioning", 4.8, 4, ["06:00", "10:00", "16:00"], "Available", "Endurance, fat-loss, and heart-rate-zone programming specialist."),
            ("leo.trainer@example.com", "Mobility & Recovery", 4.7, 6, ["08:00", "14:00", "20:00"], "Busy", "Mobility screens, corrective exercise, and recovery planning."),
        ]
        trainers = {}
        for email, specialty, rating, sessions_today, slots, status, bio in data:
            trainer, _created = TrainerProfile.objects.update_or_create(
                user=users[email],
                defaults={
                    "specialty": specialty,
                    "rating": rating,
                    "sessions_today": sessions_today,
                    "available_slots": slots,
                    "status": status,
                    "bio": bio,
                },
            )
            trainers[email] = trainer
        return trainers

    def seed_memberships(self, users, plans):
        now = timezone.now()
        records = [
            (plans["Monthly"], now - timedelta(days=18), now + timedelta(days=12), "Active", PaymentStatus.CONFIRMED, None),
            (plans["Weekly"], now - timedelta(days=42), now - timedelta(days=35), "Completed", PaymentStatus.CONFIRMED, None),
            (plans["Daily"], now - timedelta(days=68), now - timedelta(days=67), "Completed", PaymentStatus.CONFIRMED, None),
        ]
        for plan, started_at, expires_at, status, payment_status, payment_due_at in records:
            MembershipRecord.objects.update_or_create(
                user=users["amina@example.com"],
                plan=plan,
                status=status,
                defaults={
                    "started_at": started_at,
                    "expires_at": expires_at,
                    "payment_status": payment_status,
                    "payment_due_at": payment_due_at,
                },
            )

    def seed_bookings(self, users, equipment, trainers):
        today = timezone.localdate()
        data = [
            ("Treadmill Pro X", "maya.trainer@example.com", today, "18:00", BookingStatus.CONFIRMED, PaymentStatus.CONFIRMED),
            ("Cable Crossover", "brian.trainer@example.com", today + timedelta(days=1), "07:00", BookingStatus.PENDING, PaymentStatus.PENDING),
            ("Spin Bike Row", "maya.trainer@example.com", today - timedelta(days=2), "10:00", BookingStatus.COMPLETED, PaymentStatus.CONFIRMED),
            ("Olympic Bench Press", "brian.trainer@example.com", today + timedelta(days=3), "16:00", BookingStatus.CONFIRMED, PaymentStatus.PAY_LATER),
        ]
        for equipment_name, trainer_email, date, slot, status, payment_status in data:
            Booking.objects.get_or_create(
                user=users["amina@example.com"],
                equipment=equipment[equipment_name],
                trainer=trainers[trainer_email],
                date=date,
                time_slot=slot,
                defaults={"status": status, "payment_status": payment_status},
            )

    def seed_payments(self, users):
        data = [
            ("M-Pesa STK", 6800, PaymentStatus.CONFIRMED, "MPESA-Q2F9X1"),
            ("Pay Later", 1200, PaymentStatus.PENDING, "LATER-4582"),
            ("Cash", 400, PaymentStatus.PENDING, "CASH-9044"),
        ]
        for method, amount, status, reference in data:
            PaymentRecord.objects.get_or_create(
                reference=reference,
                defaults={
                    "user": users["amina@example.com"],
                    "method": method,
                    "amount": amount,
                    "status": status,
                },
            )

    def seed_notifications(self, users):
        data = [
            (NotificationType.BOOKING, "Booking confirmed", "Your Treadmill Pro X session is confirmed for 18:00 today.", False),
            (NotificationType.MEMBERSHIP, "Membership expires soon", "Your Monthly plan has 12 days remaining.", False),
            (NotificationType.PAYMENT, "Payment pending", "Complete your Pay Later balance before your next session.", True),
            (NotificationType.TRAINER, "Trainer schedule updated", "Brian added an extra evening slot tomorrow.", True),
        ]
        for type_, title, message, is_read in data:
            Notification.objects.get_or_create(
                user=users["amina@example.com"],
                title=title,
                defaults={"type": type_, "message": message, "is_read": is_read},
            )

    def seed_feedback(self, users):
        data = [
            ("Brian Kariuki", 5, "Great technique correction and clear pacing."),
            ("Treadmill Pro X", 4, "Clean and reliable, one unit had a noisy belt."),
        ]
        for target, rating, comment in data:
            FeedbackEntry.objects.get_or_create(
                user=users["amina@example.com"],
                target=target,
                defaults={"rating": rating, "comment": comment},
            )
