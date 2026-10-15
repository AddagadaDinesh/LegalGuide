import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'legalguide.settings')


def main():
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
        '/api/admin/users/promote/',
        '/api/admin/analytics/',
    ]

    print("Testing local Django endpoints with HTTP_HOST 127.0.0.1:")
    for ep in endpoints:
        match = resolve(ep)
        resp = client.get(ep, HTTP_HOST='127.0.0.1')
        view_name = match.func.__name__ if hasattr(match.func, '__name__') else str(match.func)
        print(f"[{resp.status_code}] {ep} -> view: {view_name}")


if __name__ == '__main__':
    main()
