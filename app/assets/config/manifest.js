//= link_tree ../images
//= link_directory ../javascripts .js
//= link_directory ../stylesheets .css

// The ALTCHA widget is vendored (vendor/assets/javascripts) and only loaded on the few forms that
// show it, so it is linked on its own rather than required into application.js, which would put
// 114KB on every page of the site.
//= link altcha.js
