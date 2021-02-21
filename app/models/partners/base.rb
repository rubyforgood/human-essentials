module Partners
  class Base < ApplicationRecord
    self.abstract_class = true

    connects_to database: { writing: :partners, reading: :partners }
  end
end
