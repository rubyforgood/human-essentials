# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# FIXME - This file is generating --> undefined is not an object (evaluating 'control.data("storage-location-inventory-path").replace')
item_option = (item) ->
  "<option value='#{item.item_id}'>
     #{ item.item_name }  (#{ item.quantity })
   </option>"

$(document).on 'turbolinks:load', () ->
  control_id = "#transfer_from_id"

  $(document).on "change", control_id, (evt) ->
    control = $(evt.target)
    $.ajax
      url: control.data("storage-location-inventory-path").replace(":id", control.val())
      dataType: "json"
      success: (data) ->
        options = $.map data, item_option
        $("#transfer_line_items select").html(options)

  $(document).on "cocoon:after-insert", "form#new_transfer", (e, insertedItem) ->
    control = $(control_id)
    $.ajax
      url: control.data("storage-location-inventory-path").replace(":id", control.val())
      dataType: "json"
      success: (data) ->
        options = $.map data, item_option
        $("select", insertedItem).html(options)
