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
        print('TYPE:', type(data).__name__)
        if isinstance(data, list):
            print('COUNT:', len(data))
            item = data[0]
            print('ITEM KEYS:', sorted(item.keys()))
            if isinstance(item, dict) and 'service' in item:
                svc = item['service']
                print('SERVICE TYPE:', type(svc).__name__)
                print('SERVICE KEYS:', sorted(svc.keys()))
                print('SERVICE SAMPLE:')
                print(json.dumps(svc, indent=2)[:12000])
            else:
                print('ITEM SAMPLE:')
                print(json.dumps(item, indent=2)[:12000])
        else:
            print(json.dumps(data, indent=2)[:12000])
except urllib.error.HTTPError as e:
    print('HTTP', e.code)
    print(e.read().decode('utf-8'))
except Exception as e:
    print('ERR', type(e).__name__, e)
