// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(function() {
  $("form.edit_division a#preview_link").on("shown.bs.tab", function(e) {
    return $("#preview").html(marked.parse($("#edit textarea").val()));
  });
  $("input[data-toggle-target]").on("change", function() {
    var group = $($(this).data("toggle-target"));
    group.toggleClass("hidden", !this.checked);
    group.find("input[type=text]").prop("required", this.checked);
  });
  $(".division-title").widowFix({
    letterLimit: 10,
    prevLimit: 11
  });
  return $(".voter-table-toggle-members").click(function() {
    return $(this).toggleClass("voter-table-toggle-members-active");
  });
});
