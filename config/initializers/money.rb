# This MoneyRails::ActionViewExtension module should get loaded
# automatically when ActionView gets loaded, but very rarely when
# setting up the app locally ItemHelper is loaded beforehand which
# try to include this module and raises an uninitialized constant error.
#
# See: https://github.com/RubyMoney/money-rails/issues/614
money_gem_dir = Gem::Specification.find_by_name("money-rails").gem_dir
require "#{money_gem_dir}/lib/money-rails/helpers/action_view_extension"

MoneyRails.configure do |config|
  # set the default currency
  config.default_currency = :usd
  config.rounding_mode = BigDecimal::ROUND_HALF_UP
  config.no_cents_if_whole = false
end

Money.locale_backend = :i18n
