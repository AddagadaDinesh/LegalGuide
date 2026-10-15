import os
import sys
from pathlib import Path

try:
    from dotenv import load_dotenv
    load_dotenv(Path(__file__).resolve().parent / ".env")
except ImportError:
    pass

TOKEN = os.environ.get("PA_API_TOKEN")
if not TOKEN:
    print("ERROR: PA_API_TOKEN is not set in environment or backend/.env.")
    sys.exit(1)

BASE = 'https://www.pythonanywhere.com/api/v0/user/Dinesh03'
AUTH = {'Authorization': 'Token ' + TOKEN}
DOMAIN = 'dinesh03.pythonanywhere.com'

def upload(local, remote):
    with open(local, 'rb') as f:
        content = f.read()
    boundary = 'SyncBoundary2024abc'
    parts = [
        f'--{boundary}\r\n'.encode(),
        b'Content-Disposition: form-data; name="content"; filename="file"\r\n',
        b'Content-Type: application/octet-stream\r\n\r\n',
        content,
        f'\r\n--{boundary}--\r\n'.encode()
    ]
    body = b''.join(parts)
    hdrs = dict(AUTH)
    hdrs['Content-Type'] = f'multipart/form-data; boundary={boundary}'
    url = f'{BASE}/files/path{remote}'
    req = urllib.request.Request(url, data=body, headers=hdrs, method='POST')
    with urllib.request.urlopen(req) as resp:
        print('Uploaded', remote, resp.status)

files_to_upload = [
    (r'c:\Users\dines\OneDrive\Desktop\Court sessions Project\LegalGuide\backend\accounts\models.py', '/home/Dinesh03/legalguide/accounts/models.py'),
    (r'c:\Users\dines\OneDrive\Desktop\Court sessions Project\LegalGuide\backend\accounts\migrations\0005_userprofile_welcome_email_sent_and_more.py', '/home/Dinesh03/legalguide/accounts/migrations/0005_userprofile_welcome_email_sent_and_more.py'),
    (r'c:\Users\dines\OneDrive\Desktop\Court sessions Project\LegalGuide\backend\accounts\email_service.py', '/home/Dinesh03/legalguide/accounts/email_service.py'),
    (r'c:\Users\dines\OneDrive\Desktop\Court sessions Project\LegalGuide\backend\accounts\serializers.py', '/home/Dinesh03/legalguide/accounts/serializers.py'),
    (r'c:\Users\dines\OneDrive\Desktop\Court sessions Project\LegalGuide\backend\accounts\views.py', '/home/Dinesh03/legalguide/accounts/views.py'),
]

for local, remote in files_to_upload:
    upload(local, remote)

print('Reloading webapp...')
req_reload = urllib.request.Request(f'{BASE}/webapps/{DOMAIN}/reload/', headers=AUTH, method='POST')
with urllib.request.urlopen(req_reload, timeout=45) as resp:
    print('Reload status:', resp.status)

time.sleep(5)
try:
    with urllib.request.urlopen('https://dinesh03.pythonanywhere.com/api/health/') as r:
        print('Health response:', r.read().decode())
except Exception as e:
    print('Health check error:', e)
