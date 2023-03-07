module Partners
  module SortableHelper
    # Copied from partner's application_helper.rb
    # https://github.com/rubyforgood/partner/blob/f0df3bc0d3357461c358ab87eeceaa3d3e288ebf/app/helpers/application_helper.rb#L50-L55
    def sortable(column, title = nil)
      title ||= column.titleize
      css_class = (column == sort_column) ? "current #{sort_direction}" : nil
      direction = (column == sort_column && sort_direction == "asc") ? "desc" : "asc"
      link_to title, { sort: column, direction: direction }, { class: css_class }
    end
  end
end