import copy
import unittest
from unittest.mock import patch

from ci_scripts.testflight_existing_external import external_plan, distribute_plan, ReleaseError


class FakeASC:
    def __init__(self):
        self.writes = []
        self.groups = [{"id": "internal", "attributes": {"name": "Family", "isInternalGroup": True}},
                       {"id": "external", "attributes": {"name": "Existing", "isInternalGroup": False}}]
        self.contact = {"contactFirstName": "PRIVATE", "contactLastName": "PRIVATE",
                        "contactPhone": "PRIVATE", "contactEmail": "PRIVATE", "demoAccountRequired": False}
        self.locales = [{"attributes": {"locale": "en-US", "description": "PRIVATE",
                                        "feedbackEmail": "PRIVATE", "privacyPolicyUrl": "PRIVATE"}}]
        self.builds = {k: {"id": k, "attributes": {"version": "168", "expired": False,
                       "processingState": "VALID", "buildAudienceType": "APP_STORE_ELIGIBLE",
                       "expirationDate": "2099-01-01T00:00:00Z"}} for k in ["ios", "tvos"]}
        self.details = {k: {"id": "detail-"+k, "attributes": {"internalBuildState": "IN_BETA_TESTING",
                         "externalBuildState": "READY_FOR_BETA_SUBMISSION", "autoNotifyEnabled": False}} for k in self.builds}
        self.notes = {k: [{"id": "note-"+k, "attributes": {"locale": "en-US", "whatsNew": ""}}] for k in self.builds}
        self.reviews = {k: [] for k in self.builds}
        self.members = set()
        self.source = "a"*40

    def pages(self, path):
        if path.startswith("/v1/apps/app/betaGroups?"): return copy.deepcopy(self.groups)
        if path.startswith("/v1/apps/app/betaAppLocalizations?"): return copy.deepcopy(self.locales)
        if path.startswith("/v1/preReleaseVersions?"):
            return [{"id": k, "attributes": {"version": "2.13.1", "platform": p}} for k,p in [("ios","IOS"),("tvos","TV_OS")]]
        if path.startswith("/v1/preReleaseVersions/"):
            key=path.split("/")[3]
            return [copy.deepcopy(self.builds[key])] if key in self.builds else []
        if path.startswith("/v1/betaGroups/external/builds?"):
            return [{"id": k} for k in self.members]
        if path.startswith("/v1/builds/") and "/betaBuildLocalizations?" in path:
            return copy.deepcopy(self.notes[path.split("/")[3]])
        if path.startswith("/v1/betaAppReviewSubmissions?"):
            key=path.split("filter[build]=")[1].split("&")[0]
            return copy.deepcopy(self.reviews[key])
        raise AssertionError(path)

    def request(self, path, *, method="GET", payload=None):
        if method != "GET":
            self.writes.append((path, method, copy.deepcopy(payload)))
            data=payload["data"]
            if path == "/v1/betaAppReviewSubmissions":
                key=data["relationships"]["build"]["data"]["id"]
                self.reviews[key] = [{"id": "review-"+key, "attributes": {"betaReviewState": "WAITING_FOR_REVIEW"}}]
                self.details[key]["attributes"]["externalBuildState"] = "WAITING_FOR_BETA_REVIEW"
            elif path.startswith("/v1/buildBetaDetails/"):
                self.details[data["id"].removeprefix("detail-")]["attributes"].update(data["attributes"])
            elif path.startswith("/v1/betaBuildLocalizations/"):
                self.notes[data["id"].removeprefix("note-")][0]["attributes"].update(data["attributes"])
            elif path == "/v1/betaBuildLocalizations":
                key=data["relationships"]["build"]["data"]["id"]
                self.notes[key]=[{"id":"note-"+key,"attributes":data["attributes"]}]
            elif path.endswith("/relationships/betaGroups"):
                self.members.add(path.split("/")[3])
            else: raise AssertionError(path)
            return {}
        if path.startswith("/v1/ciBuildRuns/"):
            return {"data": {"attributes": {"number": 168, "completionStatus": "SUCCEEDED", "sourceCommit": {"commitSha": self.source}},
                              "relationships": {"workflow": {"data": {"id":"workflow"}}}}}
        if path.startswith("/v1/apps/app/betaAppReviewDetail?"): return {"data":{"attributes":copy.deepcopy(self.contact)}}
        if path.startswith("/v1/betaGroups/external?"): return {"data":copy.deepcopy(self.groups[1])}
        if path.startswith("/v1/builds/"):
            key=path.split("/")[3].split("?")[0]
            return {"data":copy.deepcopy(self.details[key] if "/buildBetaDetail?" in path else self.builds[key])}
        raise AssertionError(path)


class ExistingExternalTests(unittest.TestCase):
    def plan(self, client):
        return external_plan(client, app_id="app", tag="v2.13.1", build_run_id="run", workflow_id="workflow",
                             expected_sha="a"*40, notes={"ios":"iOS reviewed notes","tvos":"TV reviewed notes"})

    def test_plan_binds_both_builds_to_exact_successful_run_without_writes(self):
        client=FakeASC(); plan=self.plan(client)
        self.assertEqual([x["build"]["id"] for x in plan], ["ios","tvos"])
        self.assertEqual(client.writes, [])

    def test_wrong_source_stops_before_any_write(self):
        client=FakeASC(); client.source="b"*40
        with self.assertRaisesRegex(ReleaseError,"source does not match"): self.plan(client)
        self.assertEqual(client.writes, [])

    def test_one_ineligible_platform_blocks_both_before_writes(self):
        for changes in [{"expired":True}, {"expired":None}, {"processingState":"PROCESSING"},
                        {"buildAudienceType":"INTERNAL_ONLY"}, {"expirationDate":"old"},
                        {"expirationDate":"2000-01-01T00:00:00Z"}, {"expirationDate":"2099-01-01T00:00:00"}]:
            with self.subTest(changes=changes):
                client=FakeASC();client.builds["tvos"]["attributes"].update(changes)
                with self.assertRaises(ReleaseError): self.plan(client)
                self.assertEqual(client.writes, [])

    def test_review_metadata_is_reused_and_incomplete_metadata_never_repaired(self):
        for kind in ["contact","locale","demo"]:
            client=FakeASC()
            if kind=="contact":client.contact["contactEmail"]=""
            elif kind=="locale":client.locales[0]["attributes"]["description"]=""
            else: client.contact["demoAccountRequired"]=True
            with self.assertRaises(ReleaseError):self.plan(client)
            self.assertEqual(client.writes,[])

    def test_unknown_group_kind_blocks_and_no_external_groups_is_noop(self):
        client=FakeASC();client.groups[1]["attributes"]["isInternalGroup"]=None
        with self.assertRaises(ReleaseError): self.plan(client)
        client.groups=client.groups[:1]
        self.assertEqual(self.plan(client),[]);self.assertEqual(client.writes,[])

    def test_missing_exact_build_does_not_choose_another_number(self):
        client=FakeASC();client.builds["tvos"]["attributes"]["version"]="167"
        with self.assertRaises(ReleaseError):self.plan(client)
        self.assertEqual(client.writes,[])

    def test_assigns_only_existing_external_group_and_submits_once_per_build(self):
        client=FakeASC();results=distribute_plan(client,self.plan(client))
        assignments=[p for path,method,p in client.writes if path.endswith("/relationships/betaGroups")]
        self.assertEqual(assignments,[{"data":[{"type":"betaGroups","id":"external"}]}]*2)
        self.assertEqual(len([1 for path,_,_ in client.writes if path=="/v1/betaAppReviewSubmissions"]),2)
        self.assertTrue(all(r["groups"][0]["assigned"] and not r["groups"][0]["available"] for r in results))
        self.assertTrue(all(r["externalBuildState"]=="WAITING_FOR_BETA_REVIEW" for r in results))
        self.assertFalse(any("PRIVATE" in str(r) for r in results))
        self.assertFalse(any("testers" in path.lower() or "betaGroups"==path.split("/")[-1] and path.startswith("/v1/apps") for path,_,_ in client.writes))

    def test_rerun_preserves_existing_notes_memberships_and_submission(self):
        client=FakeASC();distribute_plan(client,self.plan(client));count=len(client.writes)
        distribute_plan(client,self.plan(client));self.assertEqual(len(client.writes),count)

    def test_nonempty_test_notes_are_preserved_and_absent_notes_created(self):
        client=FakeASC();client.notes["ios"][0]["attributes"]["whatsNew"]="Owner's original text"
        client.notes["tvos"]=[]
        distribute_plan(client,self.plan(client))
        self.assertEqual(client.notes["ios"][0]["attributes"]["whatsNew"],"Owner's original text")
        self.assertEqual(client.notes["tvos"][0]["attributes"]["whatsNew"],"TV reviewed notes")

    def test_existing_rejected_unknown_review_never_resubmitted(self):
        for state in ["REJECTED",None]:
            client=FakeASC();client.reviews["tvos"]=[{"attributes":{"betaReviewState":state}}]
            with self.assertRaises(ReleaseError):self.plan(client)
            self.assertEqual(client.writes,[])

    def test_changed_group_or_expiry_stops_before_that_builds_writes(self):
        for changed in ["group","expiry"]:
            client=FakeASC();plan=self.plan(client)
            if changed=="group":client.groups[1]["attributes"]["isInternalGroup"]=True
            else:client.builds["ios"]["attributes"]["expired"]=True
            with self.assertRaises(ReleaseError):distribute_plan(client,plan)
            self.assertEqual(client.writes,[])

    def test_post_failure_is_not_retried(self):
        client=FakeASC();plan=self.plan(client);original=client.request
        def request(path,**kwargs):
            if path=="/v1/betaAppReviewSubmissions":raise ReleaseError("Apple rejected POST")
            return original(path,**kwargs)
        with patch.object(client,"request",side_effect=request) as mocked:
            with self.assertRaisesRegex(ReleaseError,"Apple rejected"):distribute_plan(client,plan)
            self.assertEqual(len([c for c in mocked.call_args_list if c.args[0]=="/v1/betaAppReviewSubmissions"]),1)

    def test_receipt_rejects_build_that_expires_or_is_invalidated_during_writes(self):
        for change in [{"expired":True}, {"processingState":"INVALID"}]:
            client=FakeASC();plan=self.plan(client);original=client.request
            def request(path,**kwargs):
                response=original(path,**kwargs)
                if path=="/v1/betaAppReviewSubmissions":
                    client.builds["ios"]["attributes"].update(change)
                    client.details["ios"]["attributes"]["externalBuildState"]="IN_BETA_TESTING"
                return response
            with patch.object(client,"request",side_effect=request):
                with self.assertRaisesRegex(ReleaseError,"after distribution"):
                    distribute_plan(client,plan)

    def test_available_receipt_requires_fresh_unexpired_build_and_group_membership(self):
        client=FakeASC()
        for key in client.details:
            client.details[key]["attributes"].update(externalBuildState="IN_BETA_TESTING",autoNotifyEnabled=True)
            client.members.add(key)
            client.reviews[key]=[{"attributes":{"betaReviewState":"APPROVED"}}]
        results=distribute_plan(client,self.plan(client))
        self.assertTrue(all(r["groups"][0]["available"] and r["expired"] is False for r in results))
        self.assertFalse(any(path=="/v1/betaAppReviewSubmissions" for path,_,_ in client.writes))


if __name__ == "__main__":
    unittest.main()
