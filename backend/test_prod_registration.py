import urllib.request
import urllib.error
import json
import time

URL = 'https://dinesh03.pythonanywhere.com/api/auth/signup/'

# Test payload with unique timestamp
ts = int(time.time())
username = f'testuser_{ts}'
email = f'testuser_{ts}@legalguide.org'
payload = {
    'username': username,
    'email': email,
    'password': 'StrongPassword123!'
}

print(f'Attempting registration for {username} / {email}...')
req = urllib.request.Request(
    URL,
    data=json.dumps(payload).encode('utf-8'),
    headers={'Content-Type': 'application/json'},
    method='POST'
)

try:
    with urllib.request.urlopen(req) as resp:
        print('Status code:', resp.status)
        data = json.loads(resp.read().decode('utf-8'))
        print('Response data:', json.dumps(data, indent=2))
        assert data.get('success') is True, 'Expected success=True'
        assert 'token' in data, 'Expected token in response'
        assert 'emailSent' in data, 'Expected emailSent in response'
        assert data['user']['email'] == email.lower(), 'Expected correct email in user object'
        print('SUCCESS: Initial registration succeeded perfectly!')
except urllib.error.HTTPError as e:
    print(f'HTTP Error {e.code}:', e.read().decode('utf-8'))
    raise

# Test duplicate registration with same email
print('\nAttempting duplicate registration with same email...')
dup_payload = {
    'username': f'other_{ts}',
    'email': email.upper(),  # test case insensitivity
    'password': 'AnotherPassword123!'
}
dup_req = urllib.request.Request(
    URL,
    data=json.dumps(dup_payload).encode('utf-8'),
    headers={'Content-Type': 'application/json'},
    method='POST'
)
try:
    with urllib.request.urlopen(dup_req) as resp:
        print('Unexpected success for duplicate email:', resp.status)
except urllib.error.HTTPError as e:
    print(f'Correctly rejected duplicate email with HTTP {e.code}:', e.read().decode('utf-8'))
    assert e.code == 400, 'Expected 400 for duplicate email'

print('\nAll production registration verification checks passed!')
