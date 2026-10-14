class CreateFunctionLeadingDigitSortKey < ActiveRecord::Migration[8.1]
  def change
    create_function :leading_digit_sort_key
  end
end
