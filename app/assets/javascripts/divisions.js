// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(function() {
  $("form.edit_division a#preview_link").on("shown.bs.tab", function(e) {
    return $("#preview").html(marked.parse($("#edit textarea").val()));
  });
  $(".ai-summary-use-draft").on("click", function() {
    var $button = $(this);
    $("input[name=newtitle]").val($button.data("title"));
    $("textarea[name=newdescription]").val($button.data("description"));
  });
  $(".division-title").widowFix({
    letterLimit: 10,
    prevLimit: 11
  });
  return $(".voter-table-toggle-members").click(function() {
    return $(this).toggleClass("voter-table-toggle-members-active");
  });
});
