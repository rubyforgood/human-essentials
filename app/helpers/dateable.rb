module Dateable
  def date_params
    return {} unless params.key?(:dates)

    params.require(:dates).slice(:date_from, :date_to)
  end

  def date_range
    start_date = date_params[:date_from]&.to_date || "Jan, 2, 1970".to_date
    end_date = date_params[:date_to]&.to_date || "Jan, 1, 2037".to_date

    # Rails does a time-sensitive comparison, and the date is treated as 12:00 am that day
    # this means that timestamps for that day itself would be counted out
    # calling end_of_day present this from happening
    end_date.end_of_day

    start_date..end_date
  end
  
  def date_range_picker
    start_date = date_params[:date_from]&.split('/')
    end_date = date_params[:date_to]&.split('/')

    start_date = start_date ? "#{start_date[1]}/#{start_date[0]}/#{start_date[2]}"&.to_date : "Jan, 2, 1970".to_date
    end_date = end_date ? "#{end_date[1]}/#{end_date[0]}/#{end_date[2]}"&.to_date : "Jan, 1, 2037".to_date

    # Rails does a time-sensitive comparison, and the date is treated as 12:00 am that day
    # this means that timestamps for that day itself would be counted out
    # calling end_of_day present this from happening
    end_date.end_of_day

    start_date..end_date
  end
end
