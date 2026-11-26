# Lab vs real world

Shortcuts I took in this lab and what a real bank would do instead.

| In my lab | At a real bank |
|---|---|
| I wrote the answer key and did the review myself | A second auditor checks the answer key before the test, and the review is done by someone who didn't build the tool |
| I made the calls for Henrik, Nanna and Mads | Each person decides in their own work queue, signed in, so the decision is tied to their account |
| The review lives in a CSV and a markdown report | An access review campaign in an IGA tool like SailPoint or Entra ID Governance, and the report in an audit management system |
| Entra ID Free, so sign-in logs came from a 7-day portal export by hand | Entra ID P1 or P2 streams sign-in and audit logs to the SIEM and keeps them for years, and last-used data comes straight from Graph |
| "Unused" means not seen since tracing started on 2026-11-24 | Months of sign-in and usage history, so an unused permission is really unused |
| I pasted the evidence into the Foundry playground as text, because its chat only takes images and PDFs | The AI tool reads the evidence files through an approved, logged pipeline with no copy and paste |
| AI-003 was tested with one model on three runs | A model risk team tests it on many cases and repeat runs, and checks it again after any change |
| I raised the model's token limit from 10,000 to 200,000 a minute for the test | Capacity is planned up front, and limit changes go through a change request |
| The same person who reviewed also made the fixes the same night | The owning team makes each fix through a change ticket, and Internal Audit checks it afterwards |
| The evidence script runs by hand, signed in as me | It runs on a schedule as its own read-only identity, and the evidence lands in write-once storage |
