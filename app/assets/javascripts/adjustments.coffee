# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


item_option = (item) ->
  "<option value='#{item.item_id}'>
     #{ item.item_name } -- #{ item.quantity }
   </option>"

$ ->
  control_id = '#adjustment_storage_location_id'

  $(document).on "change", control_id, (evt) ->
    control = $(evt.target)
    $.ajax
      url: control.data("storage-location-inventory-path").replace(":id", control.val())
      dataType: "json"
      success: (data) ->
        options = $.map data, item_option
        $("#adjustment_storage_location_line_items select").html(options)

  $(document).on "cocoon:after-insert", "form#new_adjustment", (e, insertedItem) ->
    control = $(control_id)
    insertedItem.find('#_barcode-lookup-new_line_items').attr('id', '_barcode-lookup-' + ($('.nested-fields').size() - 1))
    $.ajax
      url: control.data("storage-location-inventory-path").replace(":id", control.val())
      dataType: "json"
      success: (data) ->
        options = $.map data, item_option
        console.log("inserted item", insertedItem)
        $("select", insertedItem).html(options)
