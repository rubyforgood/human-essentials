# frozen_string_literal: true

class PartnerUpdateService
  attr_accessor :partner, :params, :error

  def initialize(partner, params)
    @partner = partner
    @params = params
  end

  def call
    return false unless validation

    if partner.update(params)
      true
    else
      @error = partner.errors.full_messages.join(", ")
      false
    end
  end

  private

  def validation
    mandatory_fields = %i[name]
    missing_fields = mandatory_fields.select { |field| params[field].blank? }
    if missing_fields.any?
      @error = "Missing mandatory fields: #{missing_fields.join(', ')}"
      return false
    end
    true
  end
end
