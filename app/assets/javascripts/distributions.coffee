# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $(document).on "change", "select#distribution_storage_location_id", ->
    control = $("select#distribution_storage_location_id")
    $.ajax
      url: control.data("storage-location-inventory-path").replace(":id", control.val())
      dataType: "json"
      success: (data) ->
        options = ""
        $.each data, (index) ->
          options += "<option value=\"" + data[index].item_id + "\">" + data[index].item_name + " (#{data[index].quantity})" + "</option>\n"
        $("#transfer_line_items select").find('option').remove().end().append(options)

  $(document).on "cocoon:after-insert", "form#new_distribution", (e, insertedItem) ->
    control = $("select#distribution_storage_location_id")
    $.ajax
      url: control.data("storage-location-inventory-path").replace(":id", control.val())
      dataType: "json"
      success: (data) ->
        options = ""
        $.each data, (index) ->
          options += "<option value=\"" + data[index].item_id + "\">" + data[index].item_name + " (#{data[index].quantity})" + "</option>\n"
        $("select", insertedItem).find('option').remove().end().append(options)
