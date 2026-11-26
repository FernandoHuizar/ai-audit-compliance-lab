# K-05 evidence, the 2 extra `lindhav-disable-request-api` registrations

Saved 2026-11-25 before 7:43 PM my time (2026-11-26 03:43 UTC), before anything was changed. Read from each app's Overview, Manifest and Owners pages in the Entra admin center. Henrik Dalgaard decided to remove both (finding K-05, `reports/review_decisions.csv`).

| | First extra | Second extra |
|---|---|---|
| Object ID | b6f5f11d-4980-4993-9cc5-ff076e0fa26f | 21ed8cd7-551e-4be0-b2d0-8d3968ab3e3f |
| Application (client) ID | e0371fe1-d211-424e-ab1f-82ada3e9800f | 40082aac-619d-4808-abba-53cccdd115c5 |
| Created | 2026-11-24 03:44:03 UTC | 2026-11-24 03:44:43 UTC |
| Created by app ID | 18ed3507-a475-4ccb-b669-d66bc9f2a36e | 18ed3507-a475-4ccb-b669-d66bc9f2a36e |
| Reference (serviceManagementReference) | AI-001 | AI-001 |
| Sign-in audience | My organization only | My organization only |
| Owners | None | None |
| Secrets or certificates | None | None |
| App roles | None | None |
| Exposed scopes or Application ID URI | None | None |
| Permissions it asks for | Microsoft Graph User.Read (delegated, the default every new app gets) | Microsoft Graph User.Read (delegated, the default every new app gets) |
| Enterprise app in the tenant | Yes, same name | Yes, same name |
| State before the change | Activated | Activated |

The one that's really used is object ID 0340991b-7f52-46b5-8625-566fb471e085, client ID 99894897-bf58-46ec-998e-c743b475b0d8. It defines DisableRequest.Submit and is the token audience for AI-001's request_disable tool. It isn't touched.

Both extras were made 40 seconds apart, about 6 minutes before the real one's Logic App runs, by the same tool app ID. They're most likely leftovers from building the disable tool in the first lab's Phase 6, when a create step ran more than once. Nothing points at them. No tool connection, no Logic App and no role assignment uses either one.

## What happened to them

Filled in as each step is done.

- 2026-11-26 03:43:32 and 03:43:56 UTC (7:43 PM my time). Deactivated b6f5f11d, then 21ed8cd7, in the Entra admin center (app registration, Deactivate). The audit log shows each as "Update application" and "Update service principal". Both Overview pages showed State Deactivated. Deactivated apps can't get new tokens and can be turned back on. The real one (0340991b) still showed Activated.
- 2026-11-26 03:46:30 and 03:46:59 UTC (7:46 PM my time). Deleted b6f5f11d, then 21ed8cd7, from each Overview page. The audit log shows "Delete application" and "Remove service principal" for each, so the enterprise apps went with them.
- 2026-11-26 03:47:40 and 03:48:05 UTC (7:47 and 7:48 PM my time). Deleted both permanently from Deleted applications, 21ed8cd7 first, then b6f5f11d. The audit log shows "Hard Delete application" and "Hard delete service principal" for each. After a refresh neither is in Deleted applications, and they can't be restored. All applications now shows one `lindhav-disable-request-api`, the real one (client ID 99894897).
- Times are from the Entra audit log (`screenshots/03-entra-audit-log-fixes-k06-k05.png`).
