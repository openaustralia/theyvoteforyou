// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(function() {
  $("form.edit_division a#preview_link").on("shown.bs.tab", function(e) {
    return $("#preview").html(marked($("#edit textarea").val()));
  });
  $(".division-title").widowFix({
    letterLimit: 10,
    prevLimit: 11
  });
  return $(".voter-table-toggle-members").click(function() {
    return $(this).toggleClass("voter-table-toggle-members-active");
  });
});
