class ProfileUpdateService
  class << self
    EMPTY_STRING = "N/A".freeze
    # @param profile [Profile]
    # @param params [ActionDispatch::Http::Parameters]
    # @return [Boolean]
    def update(profile, params)
      profile.update(prepare_params(params, profile))
    end

    private

    # @param params [ActionDispatch::Http::Parameters]
    # @param profile [Profile]
    # @return params [ActionDispatch::Http::Parameters]
    def filter_params(params, profile)
      # should update the present params and the params that are already present in the profile
      params.select { |k, v| v.present? || profile.send(k).present? }
    end

    # @param params [ActionDispatch::Http::Parameters]
    # @param profile [Profile]
    # @return params [ActionDispatch::Http::Parameters]
    def prepare_params(params, profile)
      # should prepare the params for update by converting the params to string if it was a string
      filter_params(params, profile).transform_values do |v|
        if v.present?
          v
        elsif v.is_a?(String)
          EMPTY_STRING
        else
          value
        end
      end
    end
  end
end
