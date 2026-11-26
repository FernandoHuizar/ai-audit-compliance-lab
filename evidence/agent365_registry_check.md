# Agent 365 registry check

I checked this on 2026-11-24, read only, in Chrome. Nothing was changed and no trial was started. Written up as evidence on 2026-11-25 from plan section 8.

## What each place showed

| Where | Count | What's in it |
|---|---|---|
| Entra, Agents overview | 3 agent identities | AI-000, AI-001 and AI-003, the same 3 the inventory script finds |
| Entra, Agents overview | 434 agents | Shown as "in your organization, powered by A365" next to the 3 identities |
| Microsoft 365 admin center, All agents | 428 agents | Mostly Microsoft and partner catalog agents marked "Available", like Copilot, GitHub Copilot and UiPath |
| Microsoft 365 admin center, All agents, publisher "Your org" | 0 agents | Empty, even though AI-001 is the bank's own |

- `ai-001-it-helpdesk` is in the admin center list with platform Microsoft Foundry, but only when the list isn't filtered by publisher.
- AI-000 isn't in the admin center list at all.
- Microsoft's docs say the Agent 365 registry lists every agent in the tenant's catalog, including ones Microsoft and partners built, not only agents with an Entra identity. Looking at it doesn't need a license.

## Cost check at the same time

- The Microsoft 365 admin center has no licenses. Your products only shows Microsoft Entra ID Free.
- No Agent 365 trial was started. The page offers one, and it turns into a paid plan.
- Azure showed $0.52 actual for November and a $0.86 forecast against the $10 budget.

## What it means for the audit

The same tenant gives 3, 428 or 434 agents depending on where you look, and the "Your org" filter misses the bank's own agent. So the Agent 365 count can't be the system of record. For Lindhav that's the inventory script (`agent_inventory.csv`), because every row ties back to an intake record. The Agent 365 count is only a cross-check, and the report says so.
