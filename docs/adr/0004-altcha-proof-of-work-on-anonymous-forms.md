# ALTCHA proof-of-work on the anonymous forms

Bots have been submitting our forms since at least 2020 (issue #1224), putting spam in the name field so it went
out in confirmation emails and dragged down mail deliverability for every OAF project. The answer then was
`invisible_captcha`, a honeypot field plus a submission timestamp. That is still the only spam control on any
anonymous form, and a honeypot is the easiest thing for a bot to learn to skip.

We chose [ALTCHA](https://altcha.org) over a hosted captcha because it is MIT licensed, runs entirely on our own
infrastructure, sets no cookies and makes no third-party request. The sign-up page promises two lines below the
widget that none of your information goes to third parties, and a hosted captcha would make that untrue. It is
also no work to run: there is no account, no API key and no service to watch.

It protects the four anonymous Devise forms: sign up, log in, password reset request and resend confirmation.
Three of the four send email, so an unchecked bot spends our mail reputation, and the password reset form is the
worst of them because it will send to any address given.

`invisible_captcha` stays. The two cost nothing, catch different kinds of bot, and the honeypot is the only thing
still standing whenever the ALTCHA flags are off.

## How it works

The browser is given a challenge whose parameters we sign with an HMAC, and has to derive a key matching the
prefix we signed. The prefix is the whole first half of the key, so there is no shortcut: the browser walks up
from counter 0 to the counter we picked, one key derivation per step. Measured on a developer machine with
PBKDF2/SHA-256 at cost 2000 and a counter between 100 and 300:

- issuing a challenge, once per form render: **0.72ms**
- checking an answer, once per submission: **0.16ms**, and the same whether the answer is good, forged or replayed
- solving, in the browser: **131ms** in Ruby on that machine, so roughly half a second to a second and a half on a
  phone

That asymmetry, about 200 to 1, is the whole idea. Confirm the browser figure against a real phone during the
log-only phase rather than trusting the arithmetic.

Both HMAC secrets are derived from `secret_key_base` rather than stored in credentials, because
`config/credentials.yml.enc` and `config/master.key` are gitignored and there is no credentials store in
development or test.

## Consequences

- **People without JavaScript cannot use these four forms while `altcha_enforce` is on.** This breaks design
  principle 4, progressive enhancement, and it is wider than "JavaScript turned off": it also excludes browsers
  without WebCrypto or Web Workers, so genuinely old phones and text-mode browsers. It is a deliberate trade, not
  an oversight. The escape hatch is the contact address in the rejection message and a person who can create an
  account by hand. Reopen the trade if the log-only phase shows the excluded group is large.
- **Two Flipper flags, and `altcha_enforce` ANDs with `altcha`.** `altcha` renders the widget and logs outcomes
  without blocking; `altcha_enforce` turns a failure into a rejection. Making enforcement depend on `altcha`
  means switching `altcha` off is a complete rollback on its own, with no deploy. Use the on/off gate only: the
  form is rendered by one request and submitted by another, so a percentage gate can hand somebody a form with no
  widget and then refuse their submission.
- **The challenge is embedded in the page, not fetched from an endpoint.** An endpoint would be separately
  targetable and this app has no rate limiting of any kind, whereas embedding attaches the cost to a page render
  that was doing database and template work anyway. It also saves a route, a controller and a round trip. The
  cost is that the widget cannot refresh an expired challenge in place, so a submission after 30 minutes
  re-renders the form with a fresh challenge and the retry works. If the log-only phase shows expiry rejections
  are common, moving to an endpoint is a one-line change to the `challenge` attribute plus a route.
- **These four pages must never be proxy-cached.** They carry CSRF tokens so they cannot be today, but if a CDN
  is ever put in front of the site and these pages are cached, every visitor shares one challenge and the replay
  guard rejects all but the first.
- **Solved challenges are spent once, recorded in `Rails.cache`.** Without it one solved challenge buys half an
  hour of resubmission, which on the password reset form is half an hour of sending email. This is the first use
  of `Rails.cache` anywhere in the app. Memcached can evict a marker early under pressure, which would allow a
  replay; that is accepted. The guard runs after signature verification, so nobody can fill the cache with
  invented signatures.
- **Challenges are scoped to a form** via the signed `data` parameter, so an answer solved on the sign-up page
  cannot be spent against password reset.
- **Challenges are not bound to the session.** The session store is a cookie, so a nonce cannot be revoked: an
  attacker replaying an old payload replays the old cookie with it. Binding would add a failure mode and buy
  nothing. Do not reopen this without also changing the session store.
- **The widget is vendored, not loaded from a CDN**, at `vendor/assets/javascripts/altcha.js`. It is the
  unmodified UMD build of widget v3, which registers `<altcha-widget>` on load and inlines its web workers as
  `data:` URIs, so one file is all that needs serving. It is linked separately in
  `app/assets/config/manifest.js` rather than required into `application.js`, which would put 114KB on every
  page. Widget v3 speaks challenge protocol v2, which is what the gem's `Altcha::V2` implements; widget v2 and
  earlier speak v1 and will not verify. Check that pairing before upgrading either side.
- **If a Content Security Policy is ever turned on** (`config/initializers/content_security_policy.rb` is sitting
  there commented out), the inlined workers need `worker-src` to allow `data:`.
- ALTCHA is a cost multiplier, not a rate limiter. At about a second per submission a determined attacker can
  still send a few thousand password reset emails a day. If email flooding turns out to be the real problem,
  `rack-attack` is the complementary tool. That is a separate decision.
