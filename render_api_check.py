import json
import urllib.request
import urllib.error
import os

key = os.environ.get('RENDER_API_KEY')
if not key:
    raise RuntimeError('RENDER_API_KEY not set')
url = 'https://api.render.com/v1/services'
req = urllib.request.Request(url, headers={
    'Authorization': f'Bearer {key}',
    'Accept': 'application/json'
})
try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = json.load(resp)
        print('OK', type(data).__name__, len(data) if isinstance(data, list) else 'notlist')
        if isinstance(data, list):
            for svc in data[:20]:
                print(svc.get('name'), svc.get('id') or svc.get('serviceId'), svc.get('serviceDetails', {}).get('url') if isinstance(svc.get('serviceDetails'), dict) else svc.get('url'))
        else:
            print(json.dumps(data, indent=2)[:2000])
except urllib.error.HTTPError as e:
    print('HTTP', e.code)
    print(e.read().decode('utf-8'))
except Exception as e:
    print('ERR', type(e).__name__, e)
