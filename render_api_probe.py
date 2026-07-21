import json
import urllib.request
import urllib.error
import os

KEY = os.environ.get('RENDER_API_KEY')
if not KEY:
    raise RuntimeError('RENDER_API_KEY not set')
SERVICE_ID = 'srv-d9ab72naqgkc739cjjh0'
BASE = 'https://api.render.com/v1'
HEADERS = {
    'Authorization': f'Bearer {KEY}',
    'Accept': 'application/json',
}

ENDPOINTS = [
    f'{BASE}/services',
    f'{BASE}/services/{SERVICE_ID}',
    f'{BASE}/services/{SERVICE_ID}/env-vars',
    f'{BASE}/services/{SERVICE_ID}/env-vars?perPage=100',
]

for url in ENDPOINTS:
    print('URL=', url)
    req = urllib.request.Request(url, headers=HEADERS)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.load(resp)
            print('STATUS', resp.status)
            print('TYPE', type(data).__name__)
            if isinstance(data, dict):
                print('KEYS', sorted(data.keys()))
            elif isinstance(data, list):
                print('LENGTH', len(data))
            print(json.dumps(data, indent=2)[:12000])
    except urllib.error.HTTPError as e:
        print('HTTP', e.code)
        print(e.read().decode('utf-8'))
    except Exception as e:
        print('ERR', type(e).__name__, e)
    print('\n' + '='*80 + '\n')
