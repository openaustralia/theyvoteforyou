# Adds google analytics event tracking
# TODO: only run this is google analytics is loaded
$ ->
  # subscribe to policy
  $('.subscribe-button-form-subscribe .btn').on 'click',  (e) ->
    ga('send', 'event', 'policy', 'subscribe')

  # unsubscribe to policy
  $('.subscribe-button-form-unsubscribe .btn').on 'click',  (e) ->
    ga('send', 'event', 'policy', 'unsubscribe')

  # edit policy
  $('.link-policy-edit').on 'click',  (e) ->
    ga('send', 'event', 'policy', 'click edit link')

  # new policy
  $('.link-policy-new').on 'click',  (e) ->
    ga('send', 'event', 'policy', 'click new link')

  # submit policy
  $('.submit-policy').on 'click',  (e) ->
    ga('send', 'event', 'policy', 'click submit')

  # edit division
  $('.link-division-edit').on 'click',  (e) ->
    ga('send', 'event', 'division', 'click edit link')

  # submit division edit
  $('.submit-division-edit').on 'click',  (e) ->
    ga('send', 'event', 'division', 'click submit')

  # click signup
  $('.link-signup').on 'click',  (e) ->
    ga('send', 'event', 'user', 'click signup link')

  # submit signup
  $('.submit-signup').on 'click',  (e) ->
    ga('send', 'event', 'user', 'click submit registration')

  # share on twitter
  $('.share-link-twitter').on 'click',  (e) ->
    ga('send', 'event', 'social', 'click share', 'twitter share')

  # share on facebook
  $('.share-link-facebook').on 'click',  (e) ->
    ga('send', 'event', 'social', 'click share', 'facebook share')
