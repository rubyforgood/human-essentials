# Encapsulates methods that need some business logic
module DistributionHelper
  def pickup_day_params
    return {} unless params.key?(:filters)

    params.require(:filters).slice(:during)
  end

  def pickup_date
    now = pickup_day_params[:during]&.to_date || Time.zone.today.to_date
    end_date = now.end_of_day

    now..end_date
  end
end
