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
