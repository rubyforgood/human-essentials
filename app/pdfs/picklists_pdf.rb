# Configures a Prawn PDF template for generating Distribution manifests
class PicklistsPdf
  include Prawn::View
  include ItemsHelper

  def initialize(organization, requests)
    @requests = requests
    @organization = organization
  end

  def compute_and_render
    data = request_data

    table(data)

    render
  end

  def request_data
    data = [["Items Requested",
      "Quantity",
      "",
      "Differences/Comments"]]

    request = @requests.first
    request_items = request.request_items.map do |request_item|
      RequestItem.from_json(request_item, request)
    end

    data + request_items.map do |request_item|
      [request_item.item.name,
        request_item.quantity,
        "",
        ""]
    end
  end
end

  
