# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $("#filters.submit-on-change select#filters_interval").on "change", (e) ->
    this.form.submit()
