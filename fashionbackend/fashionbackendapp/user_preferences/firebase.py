import os
import json
import base64
import firebase_admin
from firebase_admin import credentials

def initialize_firebase():
    try:
        if firebase_admin._apps:
            return

        firebase_key_b64 = os.getenv("FIREBASE_KEY")
        if not firebase_key_b64:
            raise ValueError("FIREBASE_KEY_B64 environment variable is not set")

        key_data = base64.b64decode(firebase_key_b64).decode("utf-8")
        cred = credentials.Certificate(json.loads(key_data))
        firebase_admin.initialize_app(cred)
    except Exception as e:
        print(f"Error initializing Firebase Admin SDK: {e}")
