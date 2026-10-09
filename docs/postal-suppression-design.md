# Bounce and complaint handling for Postal mail

Shared design for They Vote for You (this repo, Rails) and OpenAustralia.org.au (`oa-org-au/twfy`, PHP).
Both send mail through Postal (postal.oaf.org.au) and neither stops sending to addresses that hard-bounce.
Planning Alerts is the reference: it already has a signed webhook, bounce handling and one-click unsubscribe.

Status: agreed in a design session on 2026-10-09. Terms (hard bounce, suppression, complaint) are in `CONTEXT.md`.

## Facts this design rests on

Read from the Postal 3.3.7 source (the version in `infrastructure/roles/internal/postal/defaults/main.yml`) and from
Planning Alerts `main`. Not tested against our live server.

- Postal receives bounce messages itself on its return path (`rp.postal.oaf.org.au`) and fires a signed webhook per mail
  server. There is no bounce mailbox feature.
- Webhook events used: `MessageDeliveryFailed` (a hard fail), `MessageBounced` (a bounce report that arrived later),
  `MessageDelayed` (each soft-fail retry), `MessageHeld` (Postal's own suppression or a hold). Each carries the
  `X-Postal-Tag` the app set, as `message.tag`.
- Webhooks are signed with the installation's RSA key, published at `https://postal.oaf.org.au/.well-known/jwks.json`.
  Postal retries a failed delivery 5 times over about 36 minutes, then drops it.
- Postal suppresses a recipient only when an address hard-fails and has already hard-failed in the previous 24 hours, or
  when soft-fail retries run out. Entries lapse after 30 days. A later bounce report never suppresses. Postal holds mail
  to a suppressed address rather than refusing it.
- Postal has no spam-complaint (feedback loop) event.
- Postal adds no `List-Unsubscribe` header. The app must.

So Postal alone keeps mailing a dead address on every send. The apps must stop sending themselves.

## Decisions

### Routing

Each app exposes a signed `POST /postal/event`, as Planning Alerts does.
It checks `X-Postal-Signature-256` against every key currently published at the JWKS URL.
A bad signature gets 403.
If the keys can't be fetched it returns 503, so Postal retries rather than losing a real event.
Unknown events and untagged mail get 200 and are ignored.

### Which address

The handler suppresses the normalised recipient address (lower-cased, trimmed) from the webhook's `message.to`.
It does not look up a record by tag.
`X-Postal-Tag` names only the kind of mail: `alert`, `confirmation` or `password`.
This works the same in Rails and PHP, and suits OpenAustralia.org.au, where one email bundles every alert for an
address and no account need exist.

### Bounce rule (same as Planning Alerts)

- `MessageBounced`: suppress at once.
- `MessageDeliveryFailed`: suppress at once, unless the receiving server's reply (the `output` field) starts with
  `5.7.x`. That is a block on our sending IP or reputation and says nothing about the person's address.
- `MessageDelayed` and `MessageHeld`: ignore.
- No app-side soft-bounce counter. Postal's own retries are the soft-bounce threshold.

### Suppression record and guard

Each app gets an `email_suppressions` table keyed by the normalised address, with the reason, the Postal event, a short
excerpt of the receiving server's reply, `suppressed_at` and `lifted_at`.
One guard sits where all mail passes: a Rails mailer interceptor here, and `send_email()` in `utility.php` for
OpenAustralia.org.au.
It skips mail tagged `alert` to a suppressed address.
It lets requested mail through (sign-up and alert confirmations, password reset), because each is one email triggered
by a fresh action, and a repeat bounce re-suppresses at once.

### Lifting a suppression

Suppression is per address and never expires.
It lifts only by a deliberate action: the person changes the address on their account, or signs up again and confirms,
or staff clear it by hand.
A repeat hard bounce suppresses again.

### What the person sees

A plain, neutral notice where they manage alerts (the subscriptions page here, the user alerts page on
OpenAustralia.org.au): emails to this address have been returning as undeliverable since a date, so alerts are paused,
and they can change their address or sign up again to resume.
OpenAustralia.org.au people with no account see nothing, because no page shows them their alerts.

### Complaints and List-Unsubscribe

Postal reports no complaints, so one-click unsubscribe is the complaint route.
Alert emails (never confirmation or password mail) carry `List-Unsubscribe` and
`List-Unsubscribe-Post: List-Unsubscribe=One-Click` (RFC 8058), as Planning Alerts does.
A click removes every alert subscription at that address, because someone pressing an inbox's Unsubscribe button wants
the mail to stop.
The landing page links back to sign up again.
Google Postmaster Tools and Microsoft's sender programs are monitored by hand. There is no automated complaint ingestion.

## Infrastructure work (openaustralia/infrastructure, GitLab)

**Ticket A, blocking.**
Add a webhook on the `theyvoteforyou` and `openaustralia` Postal mail servers pointing at `/postal/event`.
Add a Cloudflare WAF allow rule for Postal's IPv4 address on both zones, as in `terraform/planningalerts/waf.tf`.
Update step 4 of `docs/POSTAL.md`, which says webhooks exist only for the PlanningAlerts servers.
Enable each webhook only after that app's endpoint is deployed, because Postal drops events after 5 retries.

**Ticket B, not blocking the webhook work.**
Verify our sending domains in Google Postmaster Tools.
Export the recipients that hard-failed from each Postal server's message history, for the one-off clean-up.
The export is real personal data: keep it out of tickets, commits and chat.

## Order of work

Both apps proceed in parallel and don't depend on each other.

1. Suppression table and send guard, plus a one-off import of already-bounced addresses from Ticket B's export.
   The import applies the same rule as above, so it leaves out 5.7.x refusals and failures that carry no reply from the
   receiving server (for example Postal's own outbound spam check). Blocked by Ticket B for the import only.
2. Webhook endpoint, `X-Postal-Tag` on outgoing mail and the bounce rule. Blocked by Ticket A for go-live.
3. One-click List-Unsubscribe on alert emails.
4. The notice on the alerts page.

"Blocked by" means the work can't go live until the infrastructure ticket is done, not that development can't start.

## Not decided here

- Whether to raise Postal's 30-day suppression retention. Rejected for now: it only helps addresses Postal has already
  suppressed, which is few.
- Patching Postal to suppress on the first hard fail. Rejected: we would carry a fork through every manual upgrade.
- Planning Alerts is out of scope. One observation, unverified: its handler unsubscribes on any `MessageDeliveryFailed`
  whose `output` isn't a 5.7.x reply, which would include Postal-internal hard fails that carry no reply.
