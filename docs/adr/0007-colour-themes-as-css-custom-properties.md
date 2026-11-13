# Colour themes as CSS custom properties

The site has a dark theme alongside the original light one. By default it follows the visitor's operating system
setting (`prefers-color-scheme`). A System / Light / Dark menu in the site header lets the visitor override that. The
choice is saved in `localStorage` and applied as `<html data-theme="light|dark">`. "System" removes the attribute.

Every colour that differs between themes is a token in `$theme-tokens` (`app/assets/stylesheets/global/_theme.scss`),
holding its light and dark values side by side. The tokens compile to `--tvfy-*` custom properties, and stylesheets use
them through `theme("name")`, which fails the build on an unknown name. Bootstrap 3 compiles its colours in and runs
them through Sass colour functions that can't take a `var()`, so its variables are left alone.
`global/_bootstrap-theme.scss` repeats the colour declarations of the Bootstrap components the site uses, pointed at
tokens whose light values are Bootstrap's own.

## Considered options

- **An override layer**: dark-only rules under the media query and the attribute, with the light styles untouched.
  It's a smaller diff, but every coloured rule then lives in two places that can drift apart.
- **A second compiled stylesheet** swapped at runtime. That doubles the CSS to maintain and download, and it flashes
  while the second sheet loads.
- **A cookie read by the server** to set `data-theme`. That avoids an inline script, but it makes pages vary by
  cookie, which complicates any later full-page caching. We chose `localStorage` with a tiny inline script in
  `<head>` that runs before the page is drawn.

## Consequences

- A new colour goes in `$theme-tokens` with a dark value, not straight into a stylesheet. A hard-coded colour is
  simply wrong in the dark theme, and nothing catches it automatically.
- The policy position scale (`for3` to `against3`) has lighter dark values. Each "for" step and its matching
  "against" step are kept within about 0.2 of each other in contrast ratio on the dark background, so neither end of
  the scale is emphasised. Check this again when changing either end.
- A Bootstrap component the site starts using keeps its light colours in the dark theme until it is added to
  `global/_bootstrap-theme.scss`.
- The dark values apply on screen only. Printing always uses the light theme.
- Social media cards (`card_layout`) are pinned to the light theme, because they are screenshotted into shared
  images. `email.css` and the Administrate admin panel are separate stylesheets and are not themed.
- Without JavaScript, the menu stays hidden and the system setting applies.
