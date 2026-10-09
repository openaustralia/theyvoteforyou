# Email suppressions

An address with an active suppression gets no policy update emails, because it hard-bounced. Confirmation and password
reset emails are still sent. The subscriptions of a suppressed address are left in place, so lifting the suppression
resumes them. Design and terms: [#1795](https://github.com/openaustralia/theyvoteforyou/issues/1795).

## Lifting one by hand

When someone writes in about missing updates, lift the suppression on their address:

```
bundle exec rake "application:email_suppressions:lift[person@example.org]"
```

or from `rails console`:

```ruby
EmailSuppression.lift!("person@example.org")
```

Either prints or returns how many suppressions were lifted. Lifting keeps the row (it sets `lifted_at`), so the history
of why updates stopped is still there. If the address bounces again, a fresh suppression is made at once.

Addresses are matched regardless of case and surrounding whitespace.

## Checking why updates stopped

```ruby
EmailSuppression.where(address: "person@example.org").order(:suppressed_at)
```

Each row has the reason, the Postal event that caused it, a short excerpt of the receiving server's reply, and when it
was suppressed and lifted. Don't paste addresses into tickets, chat or logs.

## One-off import of addresses Postal already hard-failed

`EmailSuppressionImport` suppresses the addresses in a CSV export of Postal's history, applying the same rule as the
webhook. It leaves out refusals that blame our server (a reply starting with a 5.7.x status code) and rows with no
reply from the receiving server.

The file needs a header row with columns `address` (or `rcpt_to`) and `output` (or `reply`), and optionally `date` (or
`timestamp`), the most recent hard fail. It comes from the infrastructure export ticket.

```
bundle exec rake "application:email_suppressions:import[tmp/postal-export.csv]"
```

- It is safe to run twice: addresses that are already suppressed are counted and left alone.
- It prints counts only, never an address, so the output can be shared.
- The file is real personal data. Keep it under `tmp/` (ignored by git) and delete it afterwards. Never commit it, or
  put it in a ticket, chat or an AI conversation.
