# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/



$(document).on 'turbolinks:load', () ->
  control_id = "#donation_source"
  # TODO: This is tightly coupled to the Donation::SOURCES and that's not too shiny.
  ddp_text = "Diaper Drive"
  dpl_text = "Donation Pickup Location"
  ddp_container_id = "div.donation_diaper_drive_participant"
  dpl_container_id = "div.donation_dropoff_location"
  $(ddp_container_id).hide()
  $(dpl_container_id).hide()

  $(document).on "change", control_id, (evt) ->
    selection = $(control_id + " option").filter(':selected').text()
    
    if (selection is ddp_text)
      $(ddp_container_id).show()
      $(dpl_container_id).hide()
    else if (selection is dpl_text)
      $(ddp_container_id).hide()
      $(dpl_container_id).show()
    else
      $(ddp_container_id).hide()
      $(dpl_container_id).hide()
