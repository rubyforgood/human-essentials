class Admin::PartnersController < AdminController
  def index
    @partners = Partner.all
  end
end
