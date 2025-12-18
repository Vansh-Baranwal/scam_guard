
import urllib.request
import json
import urllib.error

API_KEY = "AIzaSyBX0vqUBT1gQeEWq6hFhAMtGkVC1akirlY"
URL = f"https://generativelanguage.googleapis.com/v1beta/models?key={API_KEY}"

try:
    with urllib.request.urlopen(URL) as response:
        data = json.loads(response.read().decode('utf-8'))
        for model in data.get('models', []):
            if 'gemini' in model['name']:
                print(model['name'])
except Exception as e:
    print(f"Error: {e}")
