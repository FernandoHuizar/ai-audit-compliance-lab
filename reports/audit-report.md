# Lindhav Bank AI agent access review, November 2026

| | |
|---|---|
| Owner | Mads Kjeldsen, Head of Internal Audit |
| Prepared by | Fernando Huizar, IAM (personal lab, Lindhav Bank is made up) |
| Review date | 2026-11-25 |
| Evidence collected | 2026-11-26 01:47 UTC (before fixes) and 03:52 UTC (after fixes) |
| Status | Final, signed off by Mads Kjeldsen on 2026-11-25 |

## Summary

Internal Audit reviewed the access of every AI agent at Lindhav Bank and of the identities that act for them. The review found 6 problems. Henrik Dalgaard, who sponsors the agents, decided each one. 2 were fixed in Entra, 1 was fixed in the intake record, 2 were kept with a reason, and 1 was kept with a risk acceptance from Nanna Friis that ends 2027-05-22. A second evidence run after the fixes shows them in place.

An AI helper, AI-003, was built to do the first read of the evidence. It was tested against an answer key I wrote by hand first. It caught 0, 3 and 2 of the 6 findings over three runs, so Nanna didn't approve it, and this review was done by a person.

The controls from the first lab mostly work. The biggest gap is log retention. Entra ID Free keeps sign-ins for 7 days, which isn't enough to investigate anything later.

## Scope

In scope.
- AI-000, Foundry's shared project identity. Disabled, sponsor Henrik Dalgaard.
- AI-001, the IT Helpdesk agent. Sponsor Henrik Dalgaard.
- AI-003, the Access Review Assistant. Sponsor Mads Kjeldsen.
- Identities that act for an agent or only exist for one. The Logic App `lindhav-ai001-disable-approval`, the app registrations named `lindhav-disable-request-api` and the Foundry project identity.
- Staff records that agents depend on, like a sponsor's or a staff member's manager.

Out of scope.
- AI-002, the Advisor Assistant. It was retired on 2026-11-23. The evidence only checks that nothing of it was left behind.
- Customer data, storage contents and the AI model itself.
- Human admin accounts. They belong to the normal yearly user access review.

## How the review was done

1. A read-only script (`scripts/collect_evidence.ps1`) pulled the agent inventory, the identities around each agent, staff and managers, Foundry traces, Logic App runs and the Azure activity log. I exported 7 days of Entra sign-in and audit logs from the portal by hand, without IP or location columns. Every file and where it came from is listed in `evidence/sources.csv`.
2. Before any AI saw the evidence, I wrote down every finding I expected and 8 things that look odd but aren't problems (`docs/answer-key.md`). It was committed to GitHub first, so the commit time proves it came first.
3. AI-003 read the evidence three times, once with an injected line telling it to report nothing. Each run was scored against the key (`reports/ai003_scorecard.md`). It didn't pass, so Nanna Friis didn't approve it for use, and the review ran on the answer key.
4. Henrik Dalgaard decided keep, fix or remove on each finding, with a one-sentence reason (`reports/review_decisions.csv`). Anything kept against the agent standard needed Nanna's risk acceptance with an end date.
5. Fixes were made in Entra the same night. I disabled first and saved the details before deleting anything. Then the script ran again into `evidence/after-fixes/`, without touching the original files.

## Findings and decisions

| ID | What's wrong | Type | Decision | Decided by | Status after review |
|---|---|---|---|---|---|
| K-01 | AI-001's tool app holds GroupMember.Read.All, and no group lookup shows in the traces | Unused access | Keep. Group lookups are part of AI-001's written purpose, and the group tests ran before tracing started | Henrik Dalgaard | Kept. Check again at AI-001's review on 2027-05-22 |
| K-02 | AI-001's tool app holds EntitlementMgmt-SubjectAccess.ReadWrite, with no matching use | Unused access | Keep. Microsoft requires it for the Entra tool, and it only lets a person request access for themselves | Henrik Dalgaard | Kept. Check again at AI-001's review |
| K-03 | DisableRequest.Submit sits on the shared Foundry project identity, not on AI-001's own identity | Too much access | Keep with risk acceptance. Only AI-001 has the request tool, and Nanna still approves every disable | Henrik Dalgaard, risk accepted by Nanna Friis | Accepted until 2027-05-22, written in AI-001's intake record |
| K-04 | The Logic App's identity holds User.EnableDisableAccount.All and User.Read.All, and no intake record listed them | Too much access | Fix the record, keep the access. The 2 permissions are already the smallest that work | Henrik Dalgaard | Fixed. AI-001's intake record now lists the identity and its permissions |
| K-05 | 2 extra app registrations named `lindhav-disable-request-api` with no owner, role, secret or use | Unused access | Remove. They're leftovers from building the disable tool | Henrik Dalgaard | Fixed. Details saved, deactivated, then permanently deleted at 03:48 UTC on 2026-11-26 |
| K-06 | Anna Holm's manager in Entra is Louise Bach, who left and is disabled | No owner | Fix. Henrik is Louise's manager, the same rule the agent standard uses when a sponsor leaves | Henrik Dalgaard | Fixed. Her manager is Henrik Dalgaard |

Evidence for each finding is in `docs/answer-key.md`. The proof of each fix is in `evidence/after-fixes/` and `evidence/k05_extra_registrations.md`.

### Checked and not a finding

These looked odd in the evidence but are fine. They're listed so a reader doesn't raise them again.
- AI-000 is disabled but still exists. Its intake record says to keep it disabled, because deleting it could break the Foundry project.
- AI-002 shows in the traces but not in the inventory. Its last run was at 05:03:42 UTC on 2026-11-24, and the audit log shows its identity hard deleted 10 minutes later.
- AI-001's tool app has a client secret. It ends 2027-02-21, within 90 days, and it's listed in the inventory, as agent standard rule 6 asks.
- 70 failed "List Keys" requests on `lindhav-foundry`. API keys are turned off, so Azure refused them. That's the "no keys" control working.
- 3 agent runs ended with code 500. The tool calls inside them still worked, so it's a run error, not an access problem.

### Other observations

- O-01, logs aren't kept long enough. Entra ID Free keeps sign-in and audit logs for 7 days. The Foundry traces keep 30 days in the workspace and 90 days in the Application Insights tables. DORA expects logs that let a bank look back at an incident, and the AI Act asks for 6 months for high-risk AI. None of Lindhav's agents is high risk, but a 7-day window is too short for any investigation.
- O-02, AI-001's reads show the person, not the agent. AI-001 reads Entra as the staff member chatting with it, so Entra's sign-in log shows the person and the tool app. Only Foundry's traces show it was AI-001. Anyone investigating has to join the two by hand.
- O-03, the Agent 365 count isn't the system of record. The same tenant shows 3 agents, 428 or 434 depending on the page, and the "Your org" filter missed AI-001 (`evidence/agent365_registry_check.md`). Lindhav's inventory script is the system of record, because every row ties back to an intake record.

## Rules the controls map to

DORA is the main law for Lindhav Bank. NIS2 also covers banks, but NIS2 Article 4 and DORA Article 1(2) say DORA's rules apply instead. So the NIS2 row shows the matching article and says DORA covers it.

| Rule | What it asks | Lindhav control | Evidence | Result |
|---|---|---|---|---|
| DORA Art. 8(1), 8(4) and 8(6) | Know your ICT assets and who's responsible, and keep an inventory | Agent inventory script tied to intake records | `evidence/agent_inventory.csv`, `evidence/agent365_registry_check.md` | Works. It missed the identities that act for agents (K-04), which are now in the intake record |
| DORA RTS 2024/1774 Art. 20 | Unique identity per person and system, a lifecycle and records of every assignment | Own Entra agent identity per agent, intake records, offboarding | `evidence/agent_inventory.csv`, AI-002 offboarding in the Entra audit log | Works, with the K-03 exception |
| DORA RTS 2024/1774 Art. 21(a) | Need to know and least privilege | Scoped permissions, read-only tool, blocked HR test in the first lab | `evidence/agent_inventory.csv`, `evidence/usage_traces.csv` | Works. 2 unused permissions kept with a reason (K-01, K-02) |
| DORA RTS 2024/1774 Art. 21(b) | Separation of duties | The agent asks, Nanna approves, the Logic App's identity acts | `evidence/related_identities.csv`, `evidence/usage_logicapp_runs.csv` | Works. Both disable requests on 2026-11-24 waited for Nanna. She denied the first and approved the second |
| DORA RTS 2024/1774 Art. 21(c) | Few shared accounts, every action traceable | AI-000 disabled, one identity per agent | `evidence/agent_inventory.csv` | Works, with the K-03 exception and O-02 |
| DORA RTS 2024/1774 Art. 21(e)(iii) | Remove access without undue delay when it isn't needed | Offboarding, this review's removals | `evidence/k05_extra_registrations.md`, Entra audit log | Works. AI-002's identity was gone 10 minutes after its last run, and K-05 was removed the night it was found |
| DORA RTS 2024/1774 Art. 21(e)(iv) | Review access at least yearly, or every 6 months for critical systems | This review, and review dates set by risk tier | `reports/review_decisions.csv`, intake records | Works. This is the first review. AI-001 is next on 2027-05-22 |
| DORA Art. 6(4) | ICT risk management, control and internal audit kept apart | Internal Audit runs the review, outside the IT and Risk teams that built and approved the agents | Intake records, `reports/review_decisions.csv` | Works |
| NIS2 Art. 21(2)(i) and (j) | Access control, asset management and MFA | Same as the DORA rows, plus security defaults turned on in Entra so every user needs MFA | As above | DORA applies instead for a bank (NIS2 Art. 4, DORA Art. 1(2)) |
| EU AI Act Art. 4 | Take measures to support AI literacy of staff who use AI | Agent standard, intake records, sponsors who signed for what their agent does | First lab's `docs/agent-standard.md` and `docs/agent-intake.md` | Applies today. Works |
| EU AI Act Art. 26(2) and 26(6) | Human oversight by trained people, logs kept at least 6 months | Human approval on disables, a person decided every finding | `evidence/usage_logicapp_runs.csv`, `reports/review_decisions.csv` | Not required yet. Prepared for, except log retention (O-01) |
| Danish FSA guidance on AI | A register of AI models, clear owners, validation kept apart from development | Inventory, sponsors, AI-003 tested against a hand-written key | `reports/ai003_scorecard.md` | Works. The test kept a weak tool out of use |

None of Lindhav's agents is high risk. An IT helpdesk and an internal review helper aren't on the Annex III list. A credit scoring agent would be, and then Article 26 would apply from 2 December 2027, the date set by the Digital Omnibus (Regulation 2026/1744). Banks can meet Article 26's monitoring and log duties through their financial services rules.

## Limits of this review

- "Unused" means no use was seen since tracing started at 03:17:55 UTC on 2026-11-24. Earlier use isn't in the evidence.
- Entra ID Free blocks sign-in logs through Graph, so those came from a 7-day portal export. Entra changes after 05:58 UTC on 2026-11-25 aren't in the exported audit log.
- The fixes were checked with a second script run and in the Entra portal, not by a second person.
- One reviewer wrote the answer key and made the review. At a real bank, a second auditor would check the key.

## What a real bank would do next

- Stream Entra sign-in and audit logs to a SIEM and keep them for years. That needs Entra ID P1 or P2, and it closes O-01.
- Move DisableRequest.Submit onto AI-001's own identity if Foundry allows it, before the risk acceptance ends on 2027-05-22.
- Have the inventory script read the identities that act for an agent, so K-04 can't happen again without being flagged.
- Retest AI-003 with a different model or a different way of giving it the files, and only use it as a second checker after a person's review.

## Sign-off

| | |
|---|---|
| Report owner | Mads Kjeldsen, Head of Internal Audit |
| Signed off | 2026-11-25. Mads Kjeldsen accepts the findings, the decisions and the limits as written |
