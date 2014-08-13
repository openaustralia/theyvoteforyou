# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# TODO Do progressive enhancement
window.secondnav_goto = ->
  return  unless document
  return  unless document.getElementById
  el = document.getElementById("r")
  window.location = el.options[el.selectedIndex].value
  return

window.secondnav_goto2 = ->
  return  unless document
  return  unless document.getElementById
  el = document.getElementById("r2")
  window.location = el.options[el.selectedIndex].value
  return

window.secondnav_goto3 = ->
  return  unless document
  return  unless document.getElementById
  el = document.getElementById("r3")
  window.location = el.options[el.selectedIndex].value
  return
