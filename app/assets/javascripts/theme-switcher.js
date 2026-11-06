// Drives the light/dark/system menu in the site header (app/views/application/_theme_switcher.html.haml).
//
// The choice is kept in localStorage and applied as <html data-theme="light|dark">. "System" removes both, leaving
// the stylesheet to follow prefers-color-scheme. _theme_preference.html.haml applies a saved choice early in <head>,
// before the page is drawn; this file only handles changing it. See global/_theme.scss for the colours.
$(function() {
  var storageKey = "tvfy-theme";
  var $menu = $(".theme-nav");
  if (!$menu.length) return;

  function savedTheme() {
    try {
      var theme = localStorage.getItem(storageKey);
      return theme === "light" || theme === "dark" ? theme : "system";
    } catch (e) {
      return "system";
    }
  }

  function applyTheme(theme) {
    try {
      if (theme === "system") {
        localStorage.removeItem(storageKey);
      } else {
        localStorage.setItem(storageKey, theme);
      }
    } catch (e) {
      // Storage is blocked, so the choice lasts only until the next page. Still apply it to this one.
    }

    if (theme === "system") {
      document.documentElement.removeAttribute("data-theme");
    } else {
      document.documentElement.setAttribute("data-theme", theme);
    }
    showTheme(theme);
  }

  function showTheme(theme) {
    var $choices = $menu.find("[data-theme-choice]");
    $choices.attr("aria-checked", "false");
    var $chosen = $choices.filter("[data-theme-choice='" + theme + "']").attr("aria-checked", "true");

    $menu.find(".theme-nav-current").text($.trim($chosen.text()));
    $menu.find(".dropdown-toggle .theme-nav-icon")
      .removeClass("fa-circle-half-stroke fa-sun fa-moon")
      .addClass($chosen.data("theme-icon"));
  }

  $menu.on("click", "[data-theme-choice]", function(event) {
    event.preventDefault();
    applyTheme($(this).data("theme-choice"));
    // Bootstrap closes the menu on this same click. Return focus to the toggle, rather than losing it with the menu
    $menu.find(".dropdown-toggle").trigger("focus");
  });

  showTheme(savedTheme());
  $menu.removeAttr("hidden");
});
