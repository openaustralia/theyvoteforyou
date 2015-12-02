# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $("form.edit_division a#preview_link").on "shown.bs.tab", (e) ->
    $("#preview").html(marked($("#edit textarea").val()))

  $(".division-title").widowFix({
    letterLimit: 10,
    prevLimit: 11
  })

  $(".party-row").click ->
    $(this).find($(".voter-table-toggle-members")).toggleClass("voter-table-toggle-members-active")
