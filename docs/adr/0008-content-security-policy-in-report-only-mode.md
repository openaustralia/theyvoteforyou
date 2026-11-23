# Content Security Policy in report-only mode, with token pages kept out of reports

The site sends a site-wide `Content-Security-Policy-Report-Only` header, configured in
`config/initializers/content_security_policy.rb`. Browsers report what the policy would block and block nothing. The
plan to enforce it is issue #1879. Violation reports go to Sentry, using the report address derived from the Sentry DSN
in the Rails credentials. Without a DSN the policy is still sent, just with no `report-uri`.

Three pages are exceptions: password reset, email confirmation and unsubscribe. Their addresses hold a secret token, and
a CSP violation report includes the address of the page. They include `KeepOutOfCspReports`, which removes `report-uri`
from their policy and sends `Referrer-Policy: no-referrer`, so neither a report from that page nor a report from the
next page carries the token to Sentry.

## Allowed sources

- `default-src`, `form_action` and `frame-ancestors` are `'self'`. `object-src` is `'none'` and `base-uri` is `'self'`.
- `script-src` is `'self'`, the Sentry loader host `js-de.sentry-cdn.com`, and a per-request nonce for inline scripts.
  The nonce applies to `script-src` only.
- `style-src` is `'self'`, `'unsafe-inline'` and `code.cdn.mozilla.net`. `'unsafe-inline'` stays until the `style=""`
  attributes are gone.
- `font-src` is `'self'` and `code.cdn.mozilla.net`.
- `img-src` is `'self'`, `data:`, `github.com` and `avatars.githubusercontent.com`. github.com redirects contributor
  avatars to the second host.
- `connect-src` is `'self'` and the Sentry ingest host taken from the DSN.
- `worker-src` is `'self'` and `blob:`, because Sentry Replay runs in a worker built from a blob URL.

## Considered options

- **Enforce straight away.** Risks blocking a script, style or image nobody knew the site used. Report-only shows what
  breaks first, at no cost to visitors.
- **Report everywhere, including token pages.** Simplest, but puts live reset, confirmation and unsubscribe tokens in a
  third-party error tracker.
- **No reports from token pages, but keep the referrer.** Leaves a gap, as a violation report from the next page
  includes its referrer, which is the token page.
- **Strip the token from the report address.** Needs custom handling in Sentry or a proxy, which a small team would have
  to maintain.

## Consequences

- Nothing is blocked yet, so the policy gives no protection until it is enforced. Enforcing means removing
  `content_security_policy_report_only` in the initializer, once the reports have settled. Issue #1879 tracks this.
- The nonce generator and the Sentry-derived sources are read when the app boots, so changing the DSN needs a restart.
- Adding a third-party script, style, font, image or connection means adding its host to the initializer. Until
  enforcement that only affects report noise. After enforcement the feature is blocked until it is added.
- Any new page whose address holds a secret token should include `KeepOutOfCspReports`. Nothing checks this for you.
- Token pages send no referrer, so links off them arrive at other sites without one.
- `spec/requests/content_security_policy_spec.rb` covers the policy. Update it with the initializer.
