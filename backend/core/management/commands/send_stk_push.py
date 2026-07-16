from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth import get_user_model
from django.utils import timezone

from core.mpesa import stk_push, MPesaError
from core.models import PaymentRecord


class Command(BaseCommand):
    help = "Send an M-Pesa STK Push (Daraja) for testing"

    def add_arguments(self, parser):
        parser.add_argument("phone", type=str, help="Phone number in international or 07 format (e.g. 2547...) or 07...)")
        parser.add_argument("amount", type=int, help="Amount in whole units (KES)")
        parser.add_argument("--user", type=str, help="Username or email to associate the payment record")
        parser.add_argument("--account-ref", type=str, default="GYM", help="Account reference")
        parser.add_argument("--desc", type=str, default="Membership", help="Transaction description")

    def handle(self, *args, **options):
        phone = options["phone"]
        amount = options["amount"]
        account_ref = options.get("account_ref")
        desc = options.get("desc")

        user = None
        username = options.get("user")
        if username:
            User = get_user_model()
            try:
                user = User.objects.get(username=username)
            except User.DoesNotExist:
                try:
                    user = User.objects.get(email=username)
                except User.DoesNotExist:
                    raise CommandError(f"User '{username}' not found")

        self.stdout.write(f"Sending STK push to {phone} for KES {amount}...")
        try:
            resp = stk_push(phone=phone, amount=amount, account_reference=account_ref, transaction_desc=desc)
        except MPesaError as e:
            raise CommandError(f"STK push failed: {e}")

        self.stdout.write("STK push response:")
        self.stdout.write(str(resp))

        # Optionally persist a PaymentRecord if user provided
        if user:
            reference = resp.get("CheckoutRequestID") or f"STK-{int(timezone.now().timestamp())}"
            PaymentRecord.objects.create(
                user=user,
                method="M-Pesa STK",
                amount=amount,
                status="pending",
                reference=reference,
                metadata={"daraja_response": resp},
            )
            self.stdout.write(f"PaymentRecord created for user {user} with reference {reference}")

        self.stdout.write(self.style.SUCCESS("STK push dispatched (check callback for result)."))
