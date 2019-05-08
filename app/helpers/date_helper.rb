# Encapsulates methods that need some business logic
module DateHelper
  def sortable_date(date)
    date.strftime("%Y-%m-%d")
  end
end
