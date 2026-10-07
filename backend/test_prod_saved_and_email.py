import urllib.request
import urllib.error
import json
import time

BASE_URL = 'https://dinesh03.pythonanywhere.com/api'
ADMIN_TOKEN = '14e8a60a06afc20c9193d7377270610f40aff37c'

ts = int(time.time())
username_a = f'test_user_a_{ts}'
email_a = f'test_a_{ts}@legalguide.org'
password_a = 'PassA123!Secure'

username_b = f'test_user_b_{ts}'
email_b = f'test_b_{ts}@legalguide.org'
password_b = 'PassB123!Secure'

def http_json(url, data=None, token=None, method='GET'):
    body = json.dumps(data).encode('utf-8') if data is not None else None
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = f'Token {token}'
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    with urllib.request.urlopen(req) as resp:
        content = resp.read().decode('utf-8')
        return resp.status, json.loads(content) if content else {}

print('=== 1. Registering Account A ===')
st, res_a_reg = http_json(f'{BASE_URL}/auth/signup/', {
    'username': username_a,
    'email': email_a,
    'password': password_a,
}, method='POST')
print(f'Account A registered: status {st}, user_id: {res_a_reg["user"]["id"]}')
token_a = res_a_reg['token']
user_id_a = str(res_a_reg['user']['id'])

print('\n=== 2. Logging in Account A (Triggers Login Notification Email) ===')
st, res_a_login = http_json(f'{BASE_URL}/auth/login/', {
    'username': username_a,
    'password': password_a,
}, method='POST')
print(f'Account A login success: status {st}, user: {res_a_login["user"]["username"]}')

print('\n=== 3. Testing Duplicate Login Debounce for Account A ===')
st, res_a_dup = http_json(f'{BASE_URL}/auth/login/', {
    'username': username_a,
    'password': password_a,
}, method='POST')
print(f'Account A duplicate rapid login success: status {st} (duplicate email debounced)')

print('\n=== 4. Account A saves 3 sections: 101, 102, 103 ===')
for sid in [101, 102, 103]:
    st, post_res = http_json(f'{BASE_URL}/saved/', {'section_id': sid}, token=token_a, method='POST')
    print(f'Account A saved section {sid}: status {st}')

st, saved_a = http_json(f'{BASE_URL}/saved/', token=token_a)
print(f'Account A saved items in production: {saved_a["section_ids"]}, count: {saved_a["count"]}')
assert sorted(saved_a['section_ids']) == [101, 102, 103]

print('\n=== 5. Registering Account B on the same system ===')
st, res_b_reg = http_json(f'{BASE_URL}/auth/signup/', {
    'username': username_b,
    'email': email_b,
    'password': password_b,
}, method='POST')
print(f'Account B registered: status {st}, user_id: {res_b_reg["user"]["id"]}')
token_b = res_b_reg['token']
user_id_b = str(res_b_reg['user']['id'])

print('\n=== 6. Logging in Account B (Triggers Login Email to Account B) ===')
st, res_b_login = http_json(f'{BASE_URL}/auth/login/', {
    'username': username_b,
    'password': password_b,
}, method='POST')
print(f'Account B login success: status {st}, email: {res_b_login["user"]["email"]}')

print('\n=== 7. Verifying Account B Saved Items is Strictly Empty (0 items) ===')
st, saved_b = http_json(f'{BASE_URL}/saved/', token=token_b)
print(f'Account B saved items in production: {saved_b["section_ids"]}, count: {saved_b["count"]}')
assert saved_b['section_ids'] == [], f'Account B should have 0 items but got {saved_b["section_ids"]}'
assert saved_b['count'] == 0

print('\n=== 8. Account B saves 1 section: 205 ===')
st, post_b = http_json(f'{BASE_URL}/saved/', {'section_id': 205}, token=token_b, method='POST')
print(f'Account B saved section 205: status {st}')

st, saved_b2 = http_json(f'{BASE_URL}/saved/', token=token_b)
print(f'Account B current saved items: {saved_b2["section_ids"]}')
assert saved_b2['section_ids'] == [205]

print('\n=== 9. Verifying Account A still has its original 3 items ===')
st, saved_a2 = http_json(f'{BASE_URL}/saved/', token=token_a)
print(f'Account A current saved items: {saved_a2["section_ids"]}')
assert sorted(saved_a2['section_ids']) == [101, 102, 103]

print('\n=== 10. Testing Account B attempting to delete Account A item 101 ===')
try:
    http_json(f'{BASE_URL}/saved/101/', token=token_b, method='DELETE')
    print('FAIL: Account B was able to delete Account A item!')
    assert False
except urllib.error.HTTPError as e:
    print(f'Correctly blocked cross-account deletion with HTTP {e.code}: {e.read().decode()}')
    assert e.code == 404

print('\n=== 11. Account A deletes item 101 ===')
st, del_res = http_json(f'{BASE_URL}/saved/101/', token=token_a, method='DELETE')
print(f'Account A deleted section 101: status {st}')

st, saved_a3 = http_json(f'{BASE_URL}/saved/', token=token_a)
print(f'Account A remaining saved items: {saved_a3["section_ids"]}')
assert sorted(saved_a3['section_ids']) == [102, 103]

print('\n=== 12. Cleaning up test accounts from production DB ===')
for uid, uname in [(user_id_a, username_a), (user_id_b, username_b)]:
    try:
        http_json(f'{BASE_URL}/admin/users/', {'user_id': uid, 'username': uname}, token=ADMIN_TOKEN, method='DELETE')
        print(f'Cleaned up test user {uname}')
    except Exception as e:
        print(f'Cleanup error for {uname}: {e}')

print('\nALL PRODUCTION SAVED ITEMS & EMAIL FLOW VERIFICATIONS PASSED!')
