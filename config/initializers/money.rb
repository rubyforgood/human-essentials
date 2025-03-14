# This MoneyRails::ActionViewExtension module should get loaded
# automatically when ActionView is loaded, but *very* rarely when
# setting up the app locally ItemHelper is loaded beforehand,
# which depends on MoneyRails::ActionViewExtension, so without
# this line an uninitialized constant error is raised.
#
# See: https://github.com/RubyMoney/money-rails/issues/614
require "money-rails/helpers/action_view_extension"

MoneyRails.configure do |config|
  # set the default currency
  config.default_currency = :usd
  config.rounding_mode = BigDecimal::ROUND_HALF_UP
  config.no_cents_if_whole = false
end

Money.locale_backend = :i18n
