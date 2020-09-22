module Exports
  class ExportRequestService
    def initialize(requests)
      @requests = requests
      @headers = %w[Date Requestor Status]
    end

    def call
      [].tap do |csv_data|
        csv_data << headers

        rows.each do |request_row|
          csv_data << headers.map { |header| request_row[header] }
        end
      end
    end

    private

    attr_reader :requests, :headers

    def rows
      requests.map do |request|
        {
          "Date" => request.created_at.strftime("%m/%d/%Y"),
          "Requestor" => request.partner.name,
          "Status" => request.status.humanize
        }.tap do |row|
          request.request_items.each do |item_ref|
            item = grouped_items[item_ref['item_id'].to_i]&.first
            row[item.name] = item_ref['quantity']
            headers << item.name unless headers.include?(item.name)
          end
        end
      end
    end

    def grouped_items
      @grouped_items ||= Item.where(id: request_item_ids).group_by(&:id)
    end

    def request_item_ids
      requests.map do |request|
        request.request_items.map { |item| item['item_id'] }
      end.flatten
    end
  end
end
