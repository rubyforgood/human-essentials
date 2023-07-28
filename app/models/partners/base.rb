module Partners
  class Base < ApplicationRecord 
  has_paper_trail
    self.abstract_class = true
  end
end
