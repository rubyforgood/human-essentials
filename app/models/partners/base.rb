module Partners
  class Base < ApplicationRecord
    self.abstract_class = true

    unless Flipper.enabled?(:single_database)
      connects_to database: { writing: :partners, reading: :partners }
    end
  end
end
