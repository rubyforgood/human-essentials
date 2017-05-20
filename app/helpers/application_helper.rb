require 'active_support/core_ext/module/aliasing'

module ApplicationHelper
  def default_title_content
    if current_organization
      current_organization.name
    else
      "DiaperBank"
    end
  end

  # wraps link_to_unless_current to provide Foundation6 friendly <a> tags
  def navigation_link_to(*args)
    link_to_unless_current(*args) do
      content_tag(:a, args.first, class: 'active', disabled: true)
    end
  end

  ## Devise overrides

  def after_sign_in_path_for(resource)
    # default to the stored location
    stored_location_for(resource) ||
      if resource.is_a?(User) && resource.organization.present?
        # go to user's dashboard
        dashboard_path(organization_id: resource.organization.id)
      else
        # send new users to organization creation page
        new_organization_path
      end
  end

  # def after_sign_out_path_for(resource)
  # end
end
