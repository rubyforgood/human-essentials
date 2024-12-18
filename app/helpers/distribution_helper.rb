# Encapsulates methods that need some business logic
module DistributionHelper
  include ActionView::Helpers::NumberHelper
  def pickup_day_params
    return {} unless params.key?(:filters)

    params.require(:filters).slice(:during)
  end

  def pickup_date
    now = pickup_day_params[:during]&.to_date || Time.zone.today.to_date
    end_date = now.end_of_day

    now..end_date
  end

  def hashed_calendar_path
    crypt = ActiveSupport::MessageEncryptor.new(Rails.application.secret_key_base[0..31])
    calendar_distributions_url(hash: crypt.encrypt_and_sign(current_organization.id))
  end

  def distribution_shipping_cost(shipping_cost)
    (shipping_cost && shipping_cost != 0) ? number_to_currency(shipping_cost) : ""
  end
end
