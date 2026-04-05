#!/usr/bin/env python3
"""One-shot check: has v0.1.8 landed in TestFlight?"""
import json, os, sys, time, urllib.request
import jwt

app_id      = os.environ["APP_STORE_CONNECT_APP_ID"]
issuer_id   = os.environ["APP_STORE_CONNECT_ISSUER_ID"]
key_id      = os.environ["APP_STORE_CONNECT_KEY_ID"]
private_key = os.environ["APP_STORE_CONNECT_PRIVATE_KEY"].replace("\\n", "\n")
target_ver  = os.environ.get("TARGET_VERSION", "0.1.8")

now = int(time.time())
token = jwt.encode(
    {"iss": issuer_id, "aud": "appstoreconnect-v1", "iat": now, "exp": now + 1140},
    private_key, algorithm="ES256",
    headers={"alg": "ES256", "kid": key_id, "typ": "JWT"}
)

headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

url = (
    f"https://api.appstoreconnect.apple.com/v1/builds"
    f"?filter[app]={app_id}"
    f"&filter[preReleaseVersion.version]={target_ver}"
    f"&fields[builds]=version,uploadedDate,processingState,usesNonExemptEncryption"
    f"&sort=-uploadedDate&limit=5"
)
req = urllib.request.Request(url, headers=headers)
with urllib.request.urlopen(req) as resp:
    data = json.load(resp)

builds = data.get("data", [])
if not builds:
    print(f"NO BUILD YET for v{target_ver} in App Store Connect.")
    sys.exit(1)

for b in builds:
    attrs = b["attributes"]
    print(f"Build {attrs['version']} | state={attrs['processingState']} | uploaded={attrs['uploadedDate']}")
