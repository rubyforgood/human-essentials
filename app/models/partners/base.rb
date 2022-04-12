module Partners
  class Base < ApplicationRecord
    self.abstract_class = true

    begin
      unless Flipper.enabled?(:single_database)
        connects_to database: { writing: :partners, reading: :partners }
      end
    rescue ActiveRecord::NoDatabaseError
    end
  end
end
