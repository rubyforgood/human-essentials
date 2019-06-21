# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

new_option = (item, selected = false) ->
  content = "<option value=\"" + item.item_id + "\""
  content += " selected" if selected
  content += ">"
  content += item.item_name
  if( $('select.storage-location-source').attr('id') != 'audit_storage_location_id')
    content += " (#{item.quantity})"
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
  control = $("select.storage-location-source")
  if(control.length > 0 && control.val() != "")
    $.ajax
      url: control.data("storage-location-inventory-path").replace(":id", control.val())
      dataType: "json"
      success: (data) ->
        populate_dropdowns item_to_populate, data

$ ->
  control = $("select.storage-location-source")
  storage_location_required = $("form.storage-location-required").length > 0
  default_item = $(".line-item-fields select")

  $(document).on "change", "select.storage-location-source", ->
    $('#__add_line_item').addClass('disabled') if storage_location_required && !control.val()
    $('#__add_line_item').removeClass('disabled') if storage_location_required && control.val()

    request_storage_location_and_populate_item(default_item)

  $(document).on "cocoon:after-insert", "form.storage-location-required", (e, insertedItem) ->
    request_storage_location_and_populate_item($("select", insertedItem))
    insertedItem.find('#_barcode-lookup-new_line_items').attr('id', '_barcode-lookup-' + ($('.nested-fields').size() - 1))
    control = $("select.storage-location-source")
    $.ajax
      url: control.data("storage-location-inventory-path").replace(":id", control.val())
      dataType: "json"
      success: (data) ->
        populate_dropdowns $("select", insertedItem), data

  $ ->
    $('#__add_line_item').addClass('disabled') if storage_location_required && !control.val()

    request_storage_location_and_populate_item(default_item)
