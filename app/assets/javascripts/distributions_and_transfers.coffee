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

$ ->
  $(document).on "change", "select#transfer_from_id, select#distribution_storage_location_id", ->
    control = $("select#transfer_from_id, select#distribution_storage_location_id")
    $.ajax
      url: control.data("storage-location-inventory-path").replace(":id", control.val())
      dataType: "json"
      success: (data) ->
        populate_dropdowns $("#distribution_line_items select, #donation_line_items select"), data

  $(document).on "cocoon:after-insert", "form#new_transfer, form#new_distribution", (e, insertedItem) ->
    insertedItem.find('#_barcode-lookup-new_line_items').attr('id', '_barcode-lookup-' + ($('.nested-fields').size() - 1))
    control = $("select#transfer_from_id, select#distribution_storage_location_id")
    $.ajax
      url: control.data("storage-location-inventory-path").replace(":id", control.val())
      dataType: "json"
      success: (data) ->
        populate_dropdowns $("select", insertedItem), data

  $ ->
    control = $("select#transfer_from_id, select#distribution_storage_location_id")
    if (control.length is 0)
      return
    $.ajax
      url: control.data("storage-location-inventory-path").replace(":id", control.val())
      dataType: "json"
      success: (data) ->
        populate_dropdowns $("#distribution_line_items select, #donation_line_items select"), data
