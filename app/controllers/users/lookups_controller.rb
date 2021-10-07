class Users::LookupsController < ApplicationController
  skip_before_action :authorize_user
  skip_before_action :authenticate_user!

  def new
    render director.render, layout: director.layout
  end

  # TODO: flash message from logout is showing up residually on bank/partner login pages
  def create
    director.lookup params.require(:user).permit(:email, :organization)
    render director.render, layout: director.layout
  end

  private

  def director
    @director ||= ConsolidatedLoginDirector.new
  end

  # The methods below essentially ducktype this controller so that it looks
  # like a devise controller to devise-y templates, such as shared/links

  def resource
    @director
  end

  def resource_name
    @director.resource_name
  end

  def devise_mapping
    @devise_mapping ||= DeviseMappingShunt.new
  end

  helper_method :resource, :resource_name, :devise_mapping

  class DeviseMappingShunt
    def registerable?
      true
    end

    def recoverable?
      true
    end

    def confirmable?
      false
    end

    def lockable?
      false
    end

    def omniauthable?
      false
    end
  end
end
