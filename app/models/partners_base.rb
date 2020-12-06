class PartnersBase < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :partner, reading: :partner }
end
