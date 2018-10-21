# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

new_option = (item, selected = false) ->
  content = "<option value=\"" + item.item_id + "\""
  content += " selected" if selected
  content += ">"
  content += item.item_name + " (#{item.quantity})"
  content += "</option>\n"
  content

populate_dropdowns = (objects, inventory) ->
  objects.each (index, element) ->
    selected = Number($(element).find(":selected").val())
    options = ""
    $.each inventory, (index) ->
      item_id = Number(inventory[index].item_id)
      options += new_option(inventory[index], selected == item_id)
    $(element).find("option").remove().end().append(options)

request_storage_location_and_populate_item = (item_to_populate) ->
  control = $("select#transfer_from_id, select#distribution_storage_location_id")
  return if (control.length is 0 || !control.val())

  $.ajax
    url: control.data("storage-location-inventory-path").replace(":id", control.val())
    dataType: "json"
    success: (data) ->
      populate_dropdowns item_to_populate, data

$ ->
  default_item = $("#distribution_line_items select, #donation_line_items select")

  $(document).on "change", "select#transfer_from_id, select#distribution_storage_location_id", ->
    request_storage_location_and_populate_item(default_item)

  $(document).on "cocoon:after-insert", "form#new_transfer, form#new_distribution", (e, insertedItem) ->
    request_storage_location_and_populate_item($("select", insertedItem))

  $ ->
    request_storage_location_and_populate_item(default_item)
