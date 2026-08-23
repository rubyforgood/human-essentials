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

# The text of the error summary, if the response rendered one. A validation failure reports
# through the summary rather than the flash -- see design.md, "one failure, one alert" -- so
# `have_error` reads both and a spec can say "the page reported this" without caring which.
# Operational failures (a service raised, a business rule refused) still use the flash.
# `response` is reached through the matcher's delegation to the example, so it cannot be probed
# with `respond_to?`: inside a `match` block `self` is the matcher, and respond_to? is not
# delegated even though method_missing is. The first version guarded with `respond_to?(:response)`
# and therefore never read a summary at all, which looks exactly like the app being wrong.
def error_summary_text(body)
  return nil unless body.is_a?(String)

  fragment = body[/<div[^>]*data-error-summary[^>]*>(.*?)<\/div>\s*<\/div>/m] ||
    body[/<div[^>]*data-error-summary[^>]*>(.*)/m]
  return nil unless fragment

  CGI.unescapeHTML(fragment.gsub(/<[^>]+>/, " ")).squeeze(" ").strip
end

[:error, :notice, :alert, :success].each do |type|
  type_symbol = :"have_#{type}"

  # Default case checks the presence of any message of the given type,
  # but if no message exists, flash[type] is `nil`, which causes
  # the matcher to return `false`.
  RSpec::Matchers.define type_symbol do |expected = //|
    match do
      summary = if type == :error
        body = begin
          response.body
        rescue
          nil
        end
        error_summary_text(body)
      end

      if expected.is_a? Regexp
        (flash[type] =~ expected) || (summary && summary =~ expected)
      elsif expected.is_a? String
        flash[type] == expected || summary&.include?(expected)
      else
        raise ArgumentError, "Value of argument must be either a string or regular expression."
      end
    end
  end
end
