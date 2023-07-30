require "active_support/core_ext/module/aliasing"

# Encapsulates view methods that need some business logic
module ApplicationHelper
  def humanize_boolean(boolean)
    I18n.t((!!boolean).to_s)
  end

  def default_title_content
    if current_organization
      current_organization.name
    else
      "Humanessentials"
    end
  end

  def active_class(name)
    name.include?(controller_path) ? "active" : controller_path
  end

  def menu_open?(name)
    name.include?(controller_path) ? 'menu-open' : ''
  end

  def can_administrate?
    current_user.has_role?(Role::ORG_ADMIN, current_organization)
  end

  def navigation_link_to(*args)
    link_to_unless_current(*args) do
      tag.a(args.first, class: "active", disabled: true)
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

  def confirm_delete_msg(resource)
    "Are you sure you want to delete #{resource}?"
  end

  def confirm_deactivate_msg(resource)
    "Are you sure you want to deactivate #{resource}?"
  end

  def confirm_reactivate_msg(resource)
    "Are you sure you want to reactivate #{resource}?"
  end

  def confirm_restore_msg(resource)
    "Are you sure you want to restore #{resource}?"
  end

  def step_container_helper(index, active_index)
    return " active" if active_index == index
    return " done" if active_index > index

    ""
  end

  def support_ticket_form_url
    ENV["SUPPORT_TICKET_FORM_URL"]
  end

  # h/t devise source code for devise_controller?
  def admin_namespace?
    request.path_info.include?('admin')
  end

  def fullstory_script(current_user: nil)
    base_script = <<-HTML
      window['_fs_debug'] = false;
      window['_fs_host'] = 'fullstory.com';
      window['_fs_script'] = 'edge.fullstory.com/s/fs.js';
      window['_fs_org'] = '#{ENV['FULLSTORY_ORG_ID']}';
      window['_fs_namespace'] = 'FS';
      (function(m,n,e,t,l,o,g,y){
          if (e in m) {if(m.console && m.console.log) { m.console.log('FullStory namespace conflict. Please set window["_fs_namespace"].');} return;}
          g=m[e]=function(a,b,s){g.q?g.q.push([a,b,s]):g._api(a,b,s);};g.q=[];
          o=n.createElement(t);o.async=1;o.crossOrigin='anonymous';o.src='https://'+_fs_script;
          y=n.getElementsByTagName(t)[0];y.parentNode.insertBefore(o,y);
          g.identify=function(i,v,s){g(l,{uid:i},s);if(v)g(l,v,s)};g.setUserVars=function(v,s){g(l,v,s)};g.event=function(i,v,s){g('event',{n:i,p:v},s)};
          g.anonymize=function(){g.identify(!!0)};
          g.shutdown=function(){g("rec",!1)};g.restart=function(){g("rec",!0)};
          g.log = function(a,b){g("log",[a,b])};
          g.consent=function(a){g("consent",!arguments.length||a)};
          g.identifyAccount=function(i,v){o='account';v=v||{};v.acctId=i;g(o,v)};
          g.clearUserCookie=function(){};
          g._w={};y='XMLHttpRequest';g._w[y]=m[y];y='fetch';g._w[y]=m[y];
          if(m[y])m[y]=function(){return g._w[y].apply(this,arguments)};
          g._v="1.2.0";
        })(window,document,window['_fs_namespace'],'script','user');
    HTML

    if current_user.present?
      base_script += <<-HTML
        FS.setUserVars({
          "email" : "#{current_user.email}"
        });
      HTML
    end

    <<-HTML
      <script>#{base_script}</script>
    HTML
  end

  # @param source_object [ApplicationRecord]
  # @return [Integer]
  def storage_location_for_source(source_object)
    if source_object.storage_location
      return source_object.storage_location.id
    end
    if source_object.respond_to?(:partner) && source_object.partner&.default_storage_location_id
      return source_object.partner.default_storage_location_id
    end
    current_organization.default_storage_location
  end

  # Helper to create the wrapper for the sidebar_* helpers.
  #
  # Call with a block that contains calls to sidebar_item and sidebar_group
  def sidebar(**options, &block)
    options = {
      class: "nav nav-pills nav-sidebar flex-column",
      data: {
        widget: "treeview",
        accordion: "false"
      }.merge(options[:data] || {}),
      role: "menu"
    }.merge options
    content_tag :ul, **options, &block
  end

  # Create an item in the sidebar.
  #
  # Name is displayed to the user
  #
  # Path is the destination of the link.
  #
  # Icon is a Font Awesome icon name, with the leading fa- removed.  Can append
  # " fas" to the icon name to get solid varieties.
  #
  # If controller is the name of a controller, this item will be open if that
  # controller is.  If controller is true, it will parse path to determine the
  # controller name.
  def sidebar_item(name, path, icon: 'circle-o', controller: false, **)
    active = sidebar_item_active path: path, controller: controller
    content_tag(:li, class: 'nav-item') do
      link_to(path, class: "nav-link #{'active' if active}") do
        content_tag(:i, '', class: "nav-icon fa fa-#{icon}") +
          content_tag(:p, name)
      end
    end
  end

  # Returns true if the sidebar item described by path and controller is active.
  # See `sidebar_item` for descriptions of those arguments.
  def sidebar_item_active(path:, controller: false, **)
    return current_page?(path) unless controller
    if controller == true
      controller = Rails.application.routes.recognize_path(path)[:controller]
    end
    controller_path == controller
  end

  # Create a collapsible group for the sidebar.  The group will be open and
  # active if any of its children are active (see sidebar_item_active above).
  #
  # Name is displayed on the page.
  #
  # Children is an array of hashes.  The hash is passed to sidebar_item with
  # :name and :path keys extracted for the positional arguments.
  #
  # Icon is a Font Awesome icon name, with the leading fa- removed.  Can append
  # " fas" to the icon name to get solid varieties.
  #
  # If controller is the name of a controller or an array of them, this group
  # will be open if those controllers are.  Note that this is in addition to
  # being open if the children are active.
  def sidebar_group(name, children, icon: 'folder', controller: false)
    open = children.any? { |child| sidebar_item_active(**child) }
    open ||= Array.wrap(controller).include? controller_path if controller

    content_tag(:li, class: "nav-item has-treeview #{'menu-open' if open}") do
      content_tag(:a, href: '#', class: "nav-link #{'active' if open}") do
        content_tag(:i, '', class: "nav-icon fa fa-#{icon}") +
          content_tag(:p) do
            html_escape(name) + content_tag(:i, '', class: "fas fa-angle-left right")
          end
      end +
        content_tag(:ul, class: "nav nav-treeview") do
          safe_join(children.map do |child|
            sidebar_item child[:name], child[:path], **child
          end)
        end
    end
  end
end
