
import urllib.request
import json
import urllib.error

API_KEY = "AIzaSyBX0vqUBT1gQeEWq6hFhAMtGkVC1akirlY"
# Note: Using the model name we found: gemini-2.0-flash-exp
URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key={API_KEY}"

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
