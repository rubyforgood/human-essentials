module ApplicationHelper
  def default_title_content
    if current_organization
      current_organization.name
    else
      "DiaperBank"
    end
  end
end
