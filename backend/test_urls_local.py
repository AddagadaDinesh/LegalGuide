import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'legalguide.settings')
django.setup()

from django.urls import resolve
from rest_framework.test import APIClient

client = APIClient()

endpoints = [
    '/api/health/',
    '/api/health',
    '/api/categories/',
    '/api/laws/',
    '/api/auth/login/',
    '/api/auth/register/',
    '/api/auth/signup/',
    '/api/admin/status/',
    '/api/admin/users/',
    '/api/admin/analytics/',
]

print("Testing local Django endpoints with HTTP_HOST 127.0.0.1:")
for ep in endpoints:
    match = resolve(ep)
    resp = client.get(ep, HTTP_HOST='127.0.0.1')
    print(f"[{resp.status_code}] {ep} -> view: {match.func.__name__ if hasattr(match.func, '__name__') else match.func} | {resp.data if hasattr(resp, 'data') else ''}")
