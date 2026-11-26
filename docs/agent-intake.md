# Lindhav Bank AI agent intake records, AI Audit and Compliance Lab

Same format as `ai-agent-governance-lab/docs/agent-intake.md`, and the same agent standard applies (`ai-agent-governance-lab/docs/agent-standard.md`). The rows from "Agent identity object ID" to "Approved Azure roles" are what the inventory script compares with Entra and Azure, so keep their wording exact. The evidence script reads both intake files together.

## AI-003 Access Review Assistant

| Field | Answer |
|---|---|
| Requested by | Mads Kjeldsen, Head of Internal Audit, 2026-11-24 |
| Sponsor | Mads Kjeldsen |
| Purpose | Reads the agent evidence files Internal Audit gives it and flags too much access, unused access and agents with no owner. It says why for each flag and names the evidence row. It never decides, changes or approves anything |
| Data it touches | Agent names, identity IDs, permissions, sponsors, staff names and usage times from the evidence files. No customer data, no secrets |
| Can read | Only files uploaded to it in a Foundry chat. Nothing live |
| Can ask to change | Nothing |
| Must never touch | Entra, Azure, storage, any live system, customer data, secrets |
| Risk tier | Medium. It reads staff and identity data |
| Identity | Its own Entra agent identity, `lindhav-foundry-lindhav-agents-ai-003-access-reviewer-AgentIdentity`, made when it was saved in Foundry on 2026-11-24 |
| Sign-in | Its own identity. No API keys. It doesn't need to sign in to anything, since it has no tools that reach a live system |
| Agent identity object ID | 5829949b-f1ee-49c9-b629-0f253c4e5e27 |
| Tool app | none |
| Approved delegated permissions on the tool app | none |
| Approved Graph permissions on the agent identity | none |
| Approved Azure roles | none |
| Next review | 2027-05-24, 6 months for Medium |
| Decision | Approved by Nanna Friis, AI Risk Officer, 2026-11-24, on one condition. Its findings have to match a hand-written answer key before Internal Audit uses them (plan Phase 3). 2026-11-25, Nanna Friis did not approve it for Internal Audit use. The condition wasn't met. It caught 0, 3 and 2 of the 6 findings across three runs and missed different ones each time, so its output can't stand in for a person's review. The Phase 4 review runs on the hand-written answer key instead. AI-003 stays built for a later retest (`reports/ai003_scorecard.md`) |
| Status | Built 2026-11-24 in Foundry on gpt-5.4-mini with Code Interpreter as its only tool. Foundry's default web search tool and model router were taken off before anyone chatted with it. Sponsor Mads Kjeldsen, 0 permissions and 0 Entra roles. Tested 2026-11-25 on versions 2 and 3, now version 3 with reasoning effort high. Not approved for use. Kept built, not in use, waiting for a retest |

## Changes to AI-001's record after the access review

AI-001's record lives in the first lab (`ai-agent-governance-lab/docs/agent-intake.md`). The review on 2026-11-25 added 2 rows to it. They aren't copied here as a table, because the evidence script reads every table row in this file.

- Identities that act for it (finding K-04). The Logic App `lindhav-ai001-disable-approval` has its own managed identity with Microsoft Graph User.EnableDisableAccount.All and User.Read.All, approved by Nanna Friis. It only acts after she approves a disable request. The app registration `lindhav-disable-request-api` defines DisableRequest.Submit, the token audience for the request tool.
- Risk acceptance (finding K-03). DisableRequest.Submit sits on the shared Foundry project identity, not on AI-001's own identity, which goes against agent standard rule 5. Nanna Friis accepted it on 2026-11-25 until 2027-05-22, because only AI-001 has the request tool and she still approves every disable.
