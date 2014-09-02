# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $('select#r').change ->
    window.location = $('select#r').val()
  $('select#r2').change ->
    window.location = $('select#r2').val()
  $('select#r3').change ->
    window.location = $('select#r3').val()
