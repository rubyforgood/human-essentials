require 'rspec/expectations'

RSpec::Matchers.define :have_flash do |expected = {}|
  match do
    expected_value = expected.each_value.first
    expected_key = expected.each_key.first

    if expected_value.is_a? Regexp
      flash[expected_key] =~ expected_value
    elsif expected_value.is_a? String
      flash[expected_key] == expected_value
    else
      raise ArgumentError, "Value of argument must be either a string or regular expression."
    end
  end
end

[:error, :notice, :alert, :success].each do |type|
  type_symbol = "have_#{type}".to_sym

  RSpec::Matchers.define type_symbol do |expected = //|
    match do
      if expected.is_a? Regexp
        flash[type] =~ expected
      elsif expected.is_a? String
        flash[type] == expected
      else
        raise ArgumentError, "Value of argument must be either a string or regular expression."
      end
    end
  end
end
