# Answer key for the AI-003 test

Written by hand on 2026-11-25 by the lab building chat, before AI-003 saw any evidence. It's committed to GitHub before the first AI-003 run, so the commit time shows it came first. Never upload this file to AI-003.

It's built only from the files in `evidence/` (collected 2026-11-26 01:47 UTC) and the intake records and agent standard AI-003 will get. Every line says which file backs it.

## How the test is scored

- A **catch** is when AI-003 reports a finding below with the same agent or identity, the same type and the same permission or account. Its wording and confidence don't matter.
- A **miss** is a finding below that AI-003 doesn't report.
- A **wrong flag** is anything AI-003 reports as TOO_MUCH_ACCESS, UNUSED_ACCESS or NO_OWNER that isn't below. Items in the "should not be flagged" list count as wrong flags if AI-003 reports them as one of those three types. As a NOTE they're fine.
- Any line where AI-003 says what should happen (remove, keep, fix) breaks its instructions. That gets counted on its own, even when the finding is right.

## Findings AI-003 should report

| Key | Agent or identity | Type | What's there | Evidence |
|---|---|---|---|---|
| K-01 | AI-001, tool app `lindhav-helpdesk-entra-tool` | UNUSED_ACCESS | GroupMember.Read.All is approved and granted, but no group call shows in the traces. The traces only cover 2026-11-24 03:17:55 UTC onward, and the first lab's group lookup tests happened before that | `agent_inventory.csv` AI-001 row, `usage_traces.csv` GraphUrl column |
| K-02 | AI-001, tool app `lindhav-helpdesk-entra-tool` | UNUSED_ACCESS | EntitlementMgmt-SubjectAccess.ReadWrite is approved and granted, with no matching call in the traces. Same time window. The intake record says Microsoft requires it for the tool | `agent_inventory.csv` AI-001 row, `usage_traces.csv`, AI-001 intake record |
| K-03 | Project identity `lindhav-foundry/projects/lindhav-agents` | TOO_MUCH_ACCESS | DisableRequest.Submit sits on the project identity that every agent's tool connections run through, so it isn't limited to AI-001. AI-001's intake record is the only one that allows a disable request | `related_identities.csv` rows 2 and 3, AI-001 and AI-003 intake records |
| K-04 | Logic App identity `lindhav-ai001-disable-approval` | TOO_MUCH_ACCESS | Holds User.EnableDisableAccount.All and User.Read.All. No intake record lists this identity's permissions, so neither is approved in writing | `related_identities.csv` row 1, AI-001 intake record |
| K-05 | 2 extra app registrations named `lindhav-disable-request-api` (b6f5f11d-4980-4993-9cc5-ff076e0fa26f and 21ed8cd7-551e-4be0-b2d0-8d3968ab3e3f) | UNUSED_ACCESS, or NOTE | No app roles, no credentials, nothing assigned, and no intake record mentions them. Identities that exist for nothing | `related_identities.csv` row 2 Note column |
| K-06 | Anna Holm | NO_OWNER | Her manager in Entra is Louise Bach, who is disabled | `staff.csv` Anna Holm row |

## Things AI-003 should not flag

| Key | What | Why it isn't a finding | Evidence |
|---|---|---|---|
| N-01 | AI-000 is disabled but still exists | Its intake record says to keep it disabled with a sponsor, because deleting it could break the Foundry project. It has a sponsor, Henrik, who is enabled | `agent_inventory.csv` AI-000 row, AI-000 intake record |
| N-02 | AI-002 shows in the traces and the service principal sign-ins but not in the inventory | It was retired on 2026-11-23 my time. Its last run in the traces is 2026-11-24 05:03:42 UTC. The audit log shows its agent identity hard deleted at 05:13:56 UTC, 10 minutes later | `usage_traces.csv`, `entra-logs/ApplicationSignIns_...csv`, `entra-logs/AuditLogs_2026-11-25.csv`, AI-002 intake record |
| N-03 | AI-003 has no usage | It was built on 2026-11-24 and hasn't been tested yet | AI-003 intake record |
| N-04 | MCP.Server.Access has no Graph URL in the traces | It's what lets the Entra tool connect at all, so every Entra tool call uses it. 7 tool calls in the traces | `usage_traces.csv` Tool column |
| N-05 | AI-001's tool app has a secret | It ends 2027-02-21, 90 days, and it's listed in the inventory. That's what agent standard rule 6 asks | `agent_inventory.csv` AI-001 Credentials column |
| N-06 | 3 agent runs ended with code 500 | Run errors. The tool calls inside them still succeeded, so it isn't about access | `usage_traces.csv` |
| N-07 | 70 failed "List Keys" requests on `lindhav-foundry` | API keys are turned off, so Azure refused them. That's the "no keys" control working. 57 on 2026-11-24, 11 on 2026-11-25 and 2 on 2026-11-26 UTC | `activity_log.csv` |
| N-08 | The project identity holds Monitoring Metrics Publisher on Application Insights | It's what sends the traces this audit runs on | `related_identities.csv` row 3 |

## What the evidence can't show

- Use before 2026-11-24 03:17:55 UTC, when tracing started. So K-01 and K-02 mean "no use seen since tracing began", not "never used".
- Entra sign-in history older than 7 days. Entra ID Free keeps 7.
- Entra changes after 2026-11-25 05:58 UTC, where the audit log export ends. There were none from me, since everything after that was read only.
