require "active_support/core_ext/module/aliasing"

# Encapsulates view methods that need some business logic
module ApplicationHelper
  def dashboard_path_from_user
    if current_user.super_admin?
      admin_dashboard_path
    else
      dashboard_path(current_user.organization)
    end
  end

  def default_title_content
    if current_organization
      current_organization.name
    else
      "DiaperBank"
    end
  end

  def active_class(name)
    name.include?(controller_name) ? "active" : controller_name
  end

  def menu_open?(name)
    name.include?(controller_name) ? 'menu-open' : ''
  end

  def can_administrate?
    (current_user.organization_admin? && current_user.organization_id == current_organization.id)
  end

  # wraps link_to_unless_current to provide Foundation6 friendly <a> tags
  def navigation_link_to(*args)
    link_to_unless_current(*args) do
      content_tag(:a, args.first, class: "active", disabled: true)
    end
  end

  def flash_class(level)
    case level
    when "notice" then "alert notice alert-info"
    when "success" then "alert success alert-success"
    when "error" then "alert error alert-danger"
    when "alert" then "alert alert-warning"
    end
  end
  ## Devise overrides

  def after_sign_in_path_for(resource)
    # default to the stored location
    if resource.is_a?(User) && resource.organization.present?
      # go to user's dashboard
      dashboard_path(organization_id: resource.organization.id)
    else
      stored_location_for(resource) || new_organization_path
      # send new users to organization creation page
    end
  end

  def confirm_delete_msg(resource)
    "Are you sure you want to delete #{resource}?"
  end

  def confirm_restore_msg(resource)
    "Are you sure you want to restore #{resource}?"
  end

  def step_container_helper(index, active_index)
    return " active" if active_index == index
    return " done" if active_index > index

    ""
  end

  # h/t devise source code for devise_controller?
  def admin_namespace?
    request.path_info.include?('admin')
  end
end
