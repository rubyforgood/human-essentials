module Exports
  class ExportLineItemColumnsAdder
    def initialize
      @registry = []
    end

    def headers(item_headers)
      @item_headers ||= item_headers.each_with_index.to_h
      @item_headers.keys.flat_map do |header|
        @registry.inject([header]) do |arr, klass|
          arr.append(klass.convert_header(header))
        end
      end
    end

    def register(column)
      @registry.append(column)
    end

    def get_row(line_items)
      chunk_size = @registry.size + 1
      row = Array.new(@item_headers.size * chunk_size, 0)
      @registry.each_with_index do |klass, idx|
        row.each_with_index { |_, i| row[i] = klass.init_value if i % chunk_size == idx + 1 }
      end
      line_items.each do |line_item|
        idx = @item_headers[line_item.item.name]
        next unless idx

        process_additional_columns(row, idx, line_item)
      end
      row
    end

    private

    def process_additional_columns(row, idx, line_item)
      idx *= (@registry.size + 1)
      row[idx] += line_item.quantity
      @registry.each_with_index do |klass, index|
        row[idx + index + 1] += klass.value(line_item)
      end
    end
  end

  class ExportColumnsBase
    def self.convert_header(header)
      raise NotImplementedError, "Subclass must implement convert_header."
    end

    def self.init_value
      raise NotImplementedError, "Subclass must implement init_value."
    end

    def self.value(raw_value)
      raise NotImplementedError, "Subclass must implement value."
    end
  end

  class ExportInKindTotalValue < Exports::ExportColumnsBase
    def self.convert_header(header)
      "#{header} In-Kind Value"
    end

    def self.init_value
      Money.new(0)
    end

    def self.value(line_item)
      Money.new(line_item.value_per_line_item)
    end
  end
end
