import urllib.request
import urllib.error
import time

TOKEN = 'daebb744fd1e992ce59637e2e27608e78ccee132'
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
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            print('Uploaded', remote, resp.status, flush=True)
    except Exception as e:
        print('Upload failed for', remote, ':', e, flush=True)

files_to_upload = [
    (r'c:\Users\dines\OneDrive\Desktop\Court sessions Project\LegalGuide\backend\laws\models.py', '/home/Dinesh03/legalguide/laws/models.py'),
    (r'c:\Users\dines\OneDrive\Desktop\Court sessions Project\LegalGuide\backend\laws\views.py', '/home/Dinesh03/legalguide/laws/views.py'),
    (r'c:\Users\dines\OneDrive\Desktop\Court sessions Project\LegalGuide\backend\laws\serializers.py', '/home/Dinesh03/legalguide/laws/serializers.py'),
    (r'c:\Users\dines\OneDrive\Desktop\Court sessions Project\LegalGuide\backend\laws\migrations\0008_legalsection_consequences_type_and_more.py', '/home/Dinesh03/legalguide/laws/migrations/0008_legalsection_consequences_type_and_more.py'),
    (r'c:\Users\dines\OneDrive\Desktop\Court sessions Project\LegalGuide\backend\laws\migrations\0009_legalsection_provision_key_and_more.py', '/home/Dinesh03/legalguide/laws/migrations/0009_legalsection_provision_key_and_more.py'),
    (r'c:\Users\dines\OneDrive\Desktop\Court sessions Project\LegalGuide\backend\assistant\safety.py', '/home/Dinesh03/legalguide/assistant/safety.py'),
    (r'c:\Users\dines\OneDrive\Desktop\Court sessions Project\LegalGuide\backend\assistant\views.py', '/home/Dinesh03/legalguide/assistant/views.py'),
    (r'c:\Users\dines\OneDrive\Desktop\Court sessions Project\LegalGuide\backend\analytics\views.py', '/home/Dinesh03/legalguide/analytics/views.py'),
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
