import os
from xcode_cloud_testflight import AppStoreConnectClient
client = AppStoreConnectClient(key_id=os.environ["APP_STORE_CONNECT_KEY_ID"], issuer_id=os.environ.get("APP_STORE_CONNECT_ISSUER_ID", ""), private_key=os.environ["APP_STORE_CONNECT_PRIVATE_KEY"])
tag = os.environ["RELEASE_TAG"]
workflow = "08111c64-7aa6-4651-b181-b86c25543bc5"
print("Workflow conditions:", client.request(f"/v1/ciWorkflows/{workflow}?fields[ciWorkflows]=name,isEnabled,manualTagStartCondition,tagStartCondition")["data"]["attributes"], flush=True)
repository = client.request(f"/v1/ciWorkflows/{workflow}/repository")["data"]
print("Workflow repository:", repository["id"], repository["attributes"], flush=True)
for repository_id in dict.fromkeys(["3d717c8d-4c65-4f36-821b-94e10b4f639a", repository["id"]]):
    refs = client.pages(f"/v1/scmRepositories/{repository_id}/gitReferences?fields[scmGitReferences]=name,canonicalName,isDeleted,kind&limit=200")
    print("Repository", repository_id, "reference count:", len(refs), flush=True)
    for ref in refs:
        a = ref["attributes"]
        if a.get("kind") == "BRANCH" or a.get("name") == tag or a.get("canonicalName") == f"refs/tags/{tag}":
            print(ref["id"], a, flush=True)
