class ProfileUpdateService
  class << self
    # we shouldn't load the entire profile file here, so we'll just define the constant here
    EMPTY_STRING = "N/A"

    # @param profile [Profile]
    # @param params [ActionDispatch::Http::Parameters]
    # @return [Boolean]
    def update(profile, params)
      profile.update(filter_params(params, profile)).inspect
    end

    private

    # @param params [ActionDispatch::Http::Parameters]
    # @param profile [Profile]
    # @return params [ActionDispatch::Http::Parameters]
    def filter_params(params, profile)
      # should update the present params and the params that are already present in the profile
      params.select { |k, v| (v.present? || profile.send(k).present?) && v != EMPTY_STRING }
    end
  end
end
