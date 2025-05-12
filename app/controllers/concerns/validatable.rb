module Validatable
  extend ActiveSupport::Concern

  included do
    rescue_from ActionController::InvalidAuthenticityToken do
      if action_name == "validate"
        render json: {valid: false}
      else
        session_expired
      end
    end
  end
end
