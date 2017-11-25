# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $(".policy-name, .policy-comparision-position").widowFix({
      letterLimit: 10,
      prevLimit: 11
    })

  if changeSubscribeButtons? && document.getElementsByClassName("subscribe-button-form-unsubscribe").length > 0
    changeSubscribeButtons("Subscribed", "subscribe-button-active")

  peopleFilter = (index) ->
    firstName = $(this).attr('data-member-first').toUpperCase()
    lastName = $(this).attr('data-member-last').toUpperCase()
    electorateName = $(this).attr('data-member-electorate').toUpperCase()
    queryTerm = $('#policy-filter-input').val().toUpperCase()
    firstNameContainsQuery = firstName.indexOf(queryTerm) != -1
    lastNameContainsQuery = lastName.indexOf(queryTerm) != -1
    electorateNameContainsQuery = electorateName.indexOf(queryTerm) != -1
    return !firstNameContainsQuery and !lastNameContainsQuery and !electorateNameContainsQuery

  applyFilter = ->
    memberItems = $('.policy-comparision-member.member-item')
    memberItems.removeClass('member-item-hidden').show()
    memberItems.filter(peopleFilter).addClass('member-item-hidden').hide()
    # hide a policy comparision block when no members in it match the search
    policyComparisionBlocks = $('.policy-comparision-block')
    showCount = 0
    policyComparisionBlocks.each (index, element) ->
      item = $(element)
      allMemberItems = item.find('.member-item').length
      hiddenMemberItems = item.find('.member-item.member-item-hidden').length
      if allMemberItems == hiddenMemberItems
        item.hide()
      else
        item.show()
      showCount += allMemberItems - hiddenMemberItems

    # show the no matches block when there are no matches
    if showCount < 1
      $('.policy-comparision-no-matches').show()
    else
      $('.policy-comparision-no-matches').hide()

  $('#policy-filter-search').click ->
    applyFilter()

  $('#policy-filter-input').on 'input', ->
    applyFilter()

  $('#policy-filter-clear').click ->
    $('#policy-filter-input').val ''
    applyFilter()

  $('#policy-filter-clear-no-matches').click (event) ->
    event.preventDefault()
    $('#policy-filter-input').val ''
    applyFilter()
