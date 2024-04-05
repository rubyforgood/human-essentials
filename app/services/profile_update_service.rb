class ProfileUpdateService
  class << self
    # @param profile [Profile]
    # @param params [ActionDispatch::Http::Parameters]
    # @return [Boolean]
    def update(profile, params)
      profile.update(filter_params(params, profile))
    end

    private

    # @param params [ActionDispatch::Http::Parameters]
    # @param profile [Profile]
    # @return params [ActionDispatch::Http::Parameters]
    def filter_params(params, profile)
      # should update the present params and the params that are already present in the profile database
      params.select { |k, v| v.present? || profile.send(k).present? }
    end
  end
end
