// Adds google analytics event tracking
// TODO: only run this if google analytics is loaded

$(function() {
  if (typeof ga !== "undefined" && ga !== null) {
    // subscribe to policy
    $('.subscribe-button-form-subscribe .btn').on('click', function(e) {
      return ga('send', 'event', 'policy', 'subscribe');
    });
    // unsubscribe to policy
    $('.subscribe-button-form-unsubscribe .btn').on('click', function(e) {
      return ga('send', 'event', 'policy', 'unsubscribe');
    });
    // edit policy
    $('.link-policy-edit').on('click', function(e) {
      return ga('send', 'event', 'policy', 'click edit link');
    });
    // new policy
    $('.link-policy-new').on('click', function(e) {
      return ga('send', 'event', 'policy', 'click new link');
    });
    // submit policy
    $('.submit-policy').on('click', function(e) {
      return ga('send', 'event', 'policy', 'click submit');
    });
    // edit division
    $('.link-division-edit').on('click', function(e) {
      return ga('send', 'event', 'division', 'click edit link');
    });
    // submit division edit
    $('.submit-division-edit').on('click', function(e) {
      return ga('send', 'event', 'division', 'click submit');
    });
    // click signup
    $('.link-signup').on('click', function(e) {
      return ga('send', 'event', 'user', 'click signup link');
    });
    // submit signup
    $('.submit-signup').on('click', function(e) {
      return ga('send', 'event', 'user', 'click submit registration');
    });
    // share on bluesky
    $('.share-link-bluesky').on('click', function(e) {
      return ga('send', 'event', 'social', 'click share', 'bluesky share');
    });
    // share on facebook
    return $('.share-link-facebook').on('click', function(e) {
      return ga('send', 'event', 'social', 'click share', 'facebook share');
    });
  }
});
