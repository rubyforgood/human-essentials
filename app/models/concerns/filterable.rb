# H/T to http://www.justinweiss.com/articles/search-and-filter-rails-models-without-bloating-your-controller/
module Filterable
  extend ActiveSupport::Concern
  # This is the core logic behind all of the #index filters. It allows a model
  # to accept a hash of parameters to filter on, where the keys are scopes and the
  # values are arguments.
  # USAGE: Foo.class_filter({ :by_name, "name" ... })
  module ClassMethods
    def class_filter(filtering_params)
      results = where(nil)
      filtering_params.each do |key, value|
        results = results.public_send(key, value) if value.present?
      end
      results
    end
  end
end
