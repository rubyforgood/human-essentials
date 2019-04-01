$(document).ready(function () {
  $(document).on('click', '.add-item-to-distribution',function(e) {
    var target = $(e.target)
    var item_quantity = target.parent().parent().children('.item-distribution-quantity').find('.quantity').val()
    target.parent().parent().children('.item-distribution-quantity').find('.quantity').val('')
    var item_upc = target.parent().parent().children('.item-distribution-upc').find('.upc').val()
    target.parent().parent().children('.item-distribution-upc').find('.upc').val('')
    var items_total = target.parent().parent().parent().find('.distribution-total-items').data('total')
    var fulfilled = target.parent().parent().parent().find('.distribution-remaining-items').data('remaining')
    var add_items = target.parent().parent().parent().find('.distributed-item-list')
    var new_remainder = parseInt(fulfilled) + parseInt(item_quantity)
    add_items.append(`<div><span>barcode: ${item_upc} </span><span> quantity: ${item_quantity} </span></div>`)
    target.parent().parent().parent().find('.distribution-remaining-items').data('remaining', new_remainder)
    target.parent().parent().parent().find('.distribution-remaining-items').empty()
    target.parent().parent().parent().find('.distribution-remaining-items').append(`Fulfilled: ${new_remainder}`)

    if (new_remainder >= items_total) {
      target.parent().parent().parent().find('.line-item-name').append("<div>COMPLETE</div>")
    }
  })
})