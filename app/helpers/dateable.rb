require 'date'

module Dateable
  def date_params
    return {} unless params.key?(:dates)

    params.require(:dates).slice(:date_from, :date_to)
  end

  def date_range
    start_date =
      if date_params[:date_from]&.include? '/'
        Date.strptime(date_params[:date_from], '%m/%d/%Y') || "Jan, 2, 1970".to_date
      else
        date_params[:date_from]&.to_date || "Jan, 2, 1970".to_date
      end

    end_date =
      if date_params[:date_to]&.include? '/'
        Date.strptime(date_params[:date_to], '%m/%d/%Y') || "Jan, 1, 2037".to_date
      else
        date_params[:date_to]&.to_date || "Jan, 1, 2037".to_date
      end

    # Rails does a time-sensitive comparison, and the date is treated as 12:00 am that day
    # this means that timestamps for that day itself would be counted out
    # calling end_of_day present this from happening
    end_date.end_of_day

    start_date..end_date
  end
end
