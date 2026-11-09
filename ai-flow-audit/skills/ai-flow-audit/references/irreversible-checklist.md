# Irreversible-action checklist

List every agent or automation step that cannot be undone. Put a **fixed human check** in front of each. Checks stay visible in runbooks and agent prompts.

## Action classes

| Class | Examples | Fixed check (human) |
|---|---|---|
| **Send** | Email, chat, SMS, social post, webhook to customer | Recipient and body shown; human confirms send |
| **Pay** | Card charge, invoice, payroll, refund | Amount, payee, memo shown; human confirms pay |
| **Delete** | Row, file, account, branch, bucket object | Name and scope shown; human confirms delete |
| **Merge** | PR, branch, schema, customer record | Diff summary shown; human confirms merge |
| **Publish** | Site, store listing, contract PDF, ad | Live URL or artifact shown; human confirms publish |
| **Access** | New user, role bump, API key, shared link | Who gets what shown; human confirms access |
| **Legal / filing** | Signature, registration, tax submit | Document and jurisdiction shown; human confirms |

## Per-flow row

| Flow ID | Step | Irreversible class | Tool / agent | Check owner role | Check text (fixed) | In production? |
|---|---|---|---|---|---|---|
| | | Send | | | "I confirm recipient and body" | Y / N |
| | | Pay | | | "I confirm amount and payee" | |
| | | Delete | | | "I confirm name and scope" | |
| | | Merge | | | "I confirm diff summary" | |
| | | Publish | | | "I confirm live target" | |

## Audit pass

1. Walk the flow path trigger → tools → human steps → output.
2. Mark each step reversible or not. If unsure, treat as irreversible.
3. Every irreversible step needs a named role and a fixed check string.
4. Missing check = **stop ship** until added.
5. Re-run after any new tool or agent is added.

## Prompt snippet (copy for agent instructions)

```text
Before any irreversible action (send, pay, delete, merge, publish, access grant, legal submit):
STOP. Show the full payload to a human. Wait for explicit confirm. Do not retry on timeout.
```
