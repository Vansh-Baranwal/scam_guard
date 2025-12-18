
import urllib.request
import json
import urllib.error

import os

def get_api_key():
    try:
        with open('.env') as f:
            for line in f:
                if line.startswith('GEMINI_API_KEY='):
                    return line.strip().split('=')[1]
    except FileNotFoundError:
        print("Error: .env file not found")
        return None
    return None

API_KEY = get_api_key()
# Testing the requested model
URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={API_KEY}"

data = {
    "contents": [{"parts": [{"text": "Hello"}]}]
}
headers = {'Content-Type': 'application/json'}

print(f"Testing URL: {URL}")

try:
    req = urllib.request.Request(URL, data=json.dumps(data).encode('utf-8'), headers=headers)
    with urllib.request.urlopen(req) as response:
        print(f"Status Code: {response.getcode()}")
        print(f"Response: {response.read().decode('utf-8')}")
except urllib.error.HTTPError as e:
    print(f"HTTP Error: {e.code} - {e.reason}")
    print(e.read().decode('utf-8'))
except Exception as e:
    print(f"Error: {e}")
