// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(function() {
  $(".policy-name, .policy-comparision-position").widowFix({
    letterLimit: 10,
    prevLimit: 11
  });
  if ((typeof changeSubscribeButtons !== "undefined" && changeSubscribeButtons !== null) && document.getElementsByClassName("subscribe-button-form-unsubscribe").length > 0) {
    return changeSubscribeButtons("Subscribed", "subscribe-button-active");
  }
});
