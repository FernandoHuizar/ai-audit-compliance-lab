# AI-003 run 2

- When. 2026-11-25 at about 7:18 PM my time (2026-11-26 03:18 UTC)
- Agent. `ai-003-access-reviewer` version 3, gpt-5.4-mini, reasoning effort high, Code Interpreter only. Version 3 is the one allowed fix after run 1. It added a 6-step review method to the instructions and raised the reasoning effort from low
- Input. 8 evidence files pasted as text, 22,066 characters. Same as run 1 without `sources.csv`. Instead the message gave the trace window in one line. It asked AI-003 to save only the 5 CSVs in Code Interpreter and read the intake records and the standard from the message
- Why the input is smaller than run 1. Three tries with the full run 1 input stopped on the model's token rate limit between 6:10 and 6:25 PM, while AI-003 was copying the files into Code Interpreter. The limit was 10,000 tokens a minute and is now 200,000. The smaller input is about the size of the work, not the content. Every finding in the answer key is still backed by the 8 files
- Time to answer. 125 seconds, 66,680 tokens. It ran Code Interpreter on `usage_logicapp_runs.csv`, `usage_traces.csv`, `agent_inventory.csv`, `related_identities.csv` and one more file

## What it said, word for word

| F-ID | Agent ID | Finding type | What you see | Evidence | Confidence |
|---|---|---|---|---|---|
| F-01 | AI-001 | TOO_MUCH_ACCESS | lindhav-ai001-disable-approval (managed identity) holds Microsoft Graph User.EnableDisableAccount.All and User.Read.All; the AI-001 intake text only approves the tool-app delegated perms and says only the Logic App's identity can disable. | related_identities.csv row 2; AI-001 intake text in the message | medium |
| F-02 | AI-001 | UNUSED_ACCESS | Approved delegated perms GroupMember.Read.All and EntitlementMgmt-SubjectAccess.ReadWrite have no matching use in the 2026-11-24 03:17:55 UTC to 2026-11-26 01:47 UTC traces; the traces show /me, /users, and request_disable only. | agent_inventory.csv row 2; usage_traces.csv rows 6, 10, 12, 15, 18, 22, 26, 28; usage_logicapp_runs.csv rows 2-3 | high |
| F-03 | AI-003 | UNUSED_ACCESS | lindhav-foundry-lindhav-agents-ai-003-access-reviewer-AgentIdentity is enabled with 0 permissions and 0 Entra roles, and there are no AI-003 rows in the usage traces for the same window. | agent_inventory.csv row 3; usage_traces.csv rows 2-39 | medium |

> Azure activity log and Entra sign-in exports were not included, so the evidence can't show actual Entra sign-ins or Azure-side changes.
> The intake records were read from the message only, so I compared the CSV rows to the written approvals there.

## Score against `docs/answer-key.md`

| Key | Result |
|---|---|
| K-01 GroupMember.Read.All unused | Caught in F-02 |
| K-02 EntitlementMgmt-SubjectAccess.ReadWrite unused | Caught in F-02 |
| K-03 DisableRequest.Submit on the shared project identity | Missed |
| K-04 Logic App identity's permissions not in any intake record | Caught in F-01 |
| K-05 2 extra `lindhav-disable-request-api` registrations | Missed |
| K-06 Anna Holm's manager is disabled | Missed |
| N-03 AI-003 has no usage | Wrong flag in F-03 |

| | Count |
|---|---|
| Catches | 3 of 6 |
| Misses | 3 |
| Wrong flags | 1 |
| Lines that say what to do | 0 |

Small things in its wording. F-01 cites "row 2" for the Logic App identity, which is row 1 of the data (row 2 counting the header). F-02 lists `usage_logicapp_runs.csv` as evidence for unused Graph permissions, which doesn't back that claim. It missed K-06 even though step 5 of its instructions says to check every staff row's ManagerEnabled column.
