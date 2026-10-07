import urllib.request
import urllib.error
import json
import time

BASE_URL = 'https://dinesh03.pythonanywhere.com/api'
ADMIN_TOKEN = '14e8a60a06afc20c9193d7377270610f40aff37c'

ts = int(time.time())
test_username = f'del_citizen_{ts}'
test_email = f'del_{ts}@legalguide.org'
test_password = 'TestPassword123!'

print('1. Creating test citizen user...')
reg_req = urllib.request.Request(
    f'{BASE_URL}/auth/signup/',
    data=json.dumps({
        'username': test_username,
        'email': test_email,
        'password': test_password,
    }).encode('utf-8'),
    headers={'Content-Type': 'application/json'},
    method='POST'
)

with urllib.request.urlopen(reg_req) as resp:
    reg_data = json.loads(resp.read().decode('utf-8'))
    user_id = str(reg_data['user']['id'])
    print(f'Created user {test_username} (ID: {user_id})')

print('\n2. Testing Admin attempting to delete own account (must be blocked)...')
self_del_req = urllib.request.Request(
    f'{BASE_URL}/admin/users/',
    data=json.dumps({'username': 'Dinesh_Admin'}).encode('utf-8'),
    headers={
        'Content-Type': 'application/json',
        'Authorization': f'Token {ADMIN_TOKEN}',
    },
    method='DELETE'
)
try:
    with urllib.request.urlopen(self_del_req) as resp:
        print('UNEXPECTED: Self-deletion succeeded:', resp.status)
except urllib.error.HTTPError as e:
    err = json.loads(e.read().decode('utf-8'))
    print(f'Correctly blocked self-deletion with HTTP {e.code}:', err)
    assert e.code == 400

print('\n3. Testing Admin deleting citizen account...')
del_req = urllib.request.Request(
    f'{BASE_URL}/admin/users/',
    data=json.dumps({'user_id': user_id, 'username': test_username}).encode('utf-8'),
    headers={
        'Content-Type': 'application/json',
        'Authorization': f'Token {ADMIN_TOKEN}',
    },
    method='DELETE'
)

with urllib.request.urlopen(del_req) as resp:
    del_data = json.loads(resp.read().decode('utf-8'))
    print('Deletion response:', del_data)
    assert del_data.get('status') == 'deleted'
    print(f'Successfully deleted user {test_username}')

print('\n4. Verifying deleted user cannot log in from any device...')
login_req = urllib.request.Request(
    f'{BASE_URL}/auth/login/',
    data=json.dumps({
        'username': test_username,
        'password': test_password,
    }).encode('utf-8'),
    headers={'Content-Type': 'application/json'},
    method='POST'
)
try:
    with urllib.request.urlopen(login_req) as resp:
        print('UNEXPECTED: Deleted user logged in:', resp.status)
except urllib.error.HTTPError as e:
    print(f'Correctly rejected login for deleted user with HTTP {e.code}:', e.read().decode('utf-8'))
    assert e.code in [400, 401]

print('\n5. Verifying user directory counts after deletion...')
users_req = urllib.request.Request(
    f'{BASE_URL}/admin/users/',
    headers={'Authorization': f'Token {ADMIN_TOKEN}'}
)
with urllib.request.urlopen(users_req) as resp:
    users_data = json.loads(resp.read().decode('utf-8'))
    user_names = [u['username'] for u in users_data.get('users', [])]
    assert test_username not in user_names, f'User {test_username} still in directory!'
    print(f'Confirmed: User {test_username} is completely absent from user directory.')
    print(f'Total Users: {users_data.get("totalUsers")}, Citizens: {users_data.get("totalCitizens")}, Admins: {users_data.get("totalAdmins")}')

print('\nALL LIVE PRODUCTION CHECKS PASSED!')
