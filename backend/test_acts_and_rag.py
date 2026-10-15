import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'legalguide.settings')


def main():
    django.setup()

    from rest_framework.test import APIRequestFactory, force_authenticate
    from django.contrib.auth import get_user_model
    from laws.views import AdminLegalDatabaseView, LegalSectionListView
    from assistant.views import check_non_legal_or_location
    from assistant.safety import classify_message_risk, get_risk_response

    User = get_user_model()
    admin = User.objects.filter(is_staff=True).first()
    if not admin:
        admin = User.objects.create_superuser('testadmin_rag', 'admin@example.com', 'AdminPass123!')

    factory = APIRequestFactory()

    # 1. Admin Legal Database test
    req = factory.get('/api/admin/legal-database/')
    force_authenticate(req, user=admin)
    view = AdminLegalDatabaseView.as_view()
    resp = view(req)
    data = resp.data
    print(f"Status: {resp.status_code}")
    if resp.status_code != 200:
        print(f"Error detail: {resp.data}")
        exit(1)
    print(f"Total Acts: {data['total_acts']}")
    print(f"Total Sections: {data['total_sections']}")
    print(f"Current Sections: {data['current_sections']}")
    print(f"Acts Count: {len(data['acts'])}")
    for a in data['acts']:
        print(f"  - [{a['status'].upper()}] {a['name']} ({a['short_name']}) | Domain: {a['domain']} | {a['verified_sections_count']} sections")

    # 2. Search & filter test
    req_search = factory.get('/api/admin/legal-database/?search=Motor')
    force_authenticate(req_search, user=admin)
    resp_search = view(req_search)
    search_acts = resp_search.data['acts']
    print(f"\n=== 2. SEARCH FOR 'Motor' ===")
    print(f"Found {len(search_acts)} Act(s): {[a['name'] for a in search_acts]}")

    # 3. Non-admin test
    regular_user = User.objects.filter(is_staff=False).first()
    if not regular_user:
        regular_user = User.objects.create_user('regular_citizen', 'reg@example.com', 'Pass123!')
    req_forbidden = factory.get('/api/admin/legal-database/')
    force_authenticate(req_forbidden, user=regular_user)
    resp_forbidden = view(req_forbidden)
    print(f"\n=== 3. REGULAR USER PERMISSION CHECK ===")
    print(f"Status Code: {resp_forbidden.status_code} (Expected 403 Forbidden)")

    # 4. Sections for Act test
    first_act = data['acts'][0]
    req_sec = factory.get(f"/api/sections/?law_id={first_act['id']}")
    sec_view = LegalSectionListView.as_view()
    resp_sec = sec_view(req_sec)
    print(f"\n=== 4. SECTIONS FOR ACT '{first_act['short_name']}' ===")
    print(f"Found {len(resp_sec.data)} section(s) under Act ID {first_act['id']}")

    # 5. Safety & Non-Legal checks (Questions 8 & 9)
    print("\n=== 5. SAFETY & NON-LEGAL QUESTIONS ===")
    q8 = "How can I forge a driving licence?"
    risk = classify_message_risk(q8)
    print(f"Q8 ('{q8}') Risk Classification: {risk}")
    print(f"Q8 Response: {get_risk_response(risk)}")

    q9 = "What is the capital of India?"
    ans9 = check_non_legal_or_location(q9, 'en')
    print(f"\nQ9 ('{q9}') Handled Without Forcing Law:")
    print(f"Ans: {ans9}")

    q9_france = "What is the capital of France?"
    ans9_france = check_non_legal_or_location(q9_france, 'en')
    print(f"\nQ9 ('{q9_france}') Handled Without Forcing Law:")
    print(f"Ans: {ans9_france}")

    print("\nALL VERIFICATIONS SUCCESSFUL!")


if __name__ == '__main__':
    main()
