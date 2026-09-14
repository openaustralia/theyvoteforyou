# Mirror portraits rather than hot-link them

Until September 2026 every page and card embedded portraits straight from `www.openaustralia.org.au/images/mps*/`.
When that site went behind a Cloudflare managed challenge, browsers and the card screenshotter both received a
challenge page instead of a JPEG, and nothing in this app noticed (issue #1749). We now download each portrait
nightly (`application:portraits:mirror`, run by `PortraitMirror`) into `public/system/portraits/` and serve it
from there. The `people.*_image_url` columns keep the source URL; `Person#*_image_url` returns the local path.

## Considered options

- **Cloudflare path rule on openaustralia.org.au** skipping the challenge for `/images/mps*`. Fixes visitors and the
  screenshotter at once, but leaves this site's appearance dependent on another site's edge configuration, which is
  exactly what broke. Kept only as an emergency lever.
- **Allowlisting this server's IP on Cloudflare** fixes the screenshotter and new-MP discovery but not visitors'
  browsers. Done as well, so the mirror can fetch through Cloudflare; not sufficient on its own.
- **Active Storage or S3** adds a dependency and a bucket for what is a ~50MB regenerable cache.

## Consequences

- Portraits are at most one night stale relative to openaustralia.org.au. A newly discovered portrait is mirrored
  immediately by `DataLoader::People.load_missing_images!`.
- `public/system` is a Capistrano linked dir, so the cache survives deploys. Losing it costs one mirror run; the first
  deploy needs `bundle exec rake application:portraits:mirror` run once by hand.
- Popolo deployments (Ukraine) store whatever image URL the Popolo file provides and are mirrored the same way.
- openaustralia.org.au remains the source of truth for the images themselves; this site does not edit or upload them.
