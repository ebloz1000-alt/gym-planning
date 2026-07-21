import base64
import time
from datetime import datetime

import requests
from django.conf import settings


class MPesaError(Exception):
    pass


def _get_oauth_token():
    key = settings.DARAJA_CONSUMER_KEY
    secret = settings.DARAJA_CONSUMER_SECRET
    if not key or not secret:
        raise MPesaError("Daraja credentials not configured")
    url = (
        "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"
        if settings.DARAJA_ENV == "sandbox"
        else "https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"
    )
    resp = requests.get(url, auth=(key, secret), timeout=10)
    resp.raise_for_status()
    return resp.json().get("access_token")


def stk_push(phone: str, amount: int, account_reference: str = "GYM", transaction_desc: str = "Membership"):
    shortcode = settings.DARAJA_SHORTCODE
    passkey = settings.DARAJA_PASSKEY
    if not shortcode or not passkey:
        raise MPesaError("Daraja shortcode/passkey not configured")

    token = _get_oauth_token()
    timestamp = datetime.utcnow().strftime("%Y%m%d%H%M%S")
    password = base64.b64encode(f"{shortcode}{passkey}{timestamp}".encode()).decode()

    callback = settings.DARAJA_CALLBACK_URL
    if not callback:
        raise MPesaError(
            "Daraja callback URL is not configured. "
            "Set DARAJA_CALLBACK_URL to a publicly reachable HTTPS endpoint, e.g. https://your-domain/api/mpesa/callback/."
        )
    if not callback.startswith("https://"):
        raise MPesaError(
            "Daraja callback URL must use HTTPS. "
            "Use a public HTTPS tunnel (ngrok/localtunnel) for local testing, e.g. https://<subdomain>.ngrok.io/api/mpesa/callback/."
        )
    payload = {
        "BusinessShortCode": shortcode,
        "Password": password,
        "Timestamp": timestamp,
        "TransactionType": "CustomerPayBillOnline",
        "Amount": amount,
        "PartyA": phone,
        "PartyB": shortcode,
        "PhoneNumber": phone,
        "CallBackURL": callback,
        "AccountReference": account_reference,
        "TransactionDesc": transaction_desc,
    }

    url = (
        "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest"
        if settings.DARAJA_ENV == "sandbox"
        else "https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest"
    )
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    resp = requests.post(url, json=payload, headers=headers, timeout=15)
    try:
        resp.raise_for_status()
    except Exception as e:
        raise MPesaError(f"STK push failed: {e} - {resp.text}")
    return resp.json()
