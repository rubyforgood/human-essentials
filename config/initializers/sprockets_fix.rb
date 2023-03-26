# frozen_string_literal: true

module Sprockets
  module ServerWithFixedPathFingerprint

    # PATCHED: Require longer (min 10 instead of 7) fingerprint so that we can distinguish
    #  "stimulus-loading-0aa2105d29558f3eb790d411d7d8fb66.js"
    #  from
    #  "stimulus-loading.js"
    #  ... where it thinks "loading" is the fingerprint without this change
    def path_fingerprint(path)
      # WAS:
      # path[/-([0-9a-zA-Z]{7,128})\.[^.]+\z/, 1]
      # PATCH:
      path[/-([0-9a-zA-Z]{10,128})\.[^.]+\z/, 1]
    end
  end

  ::Sprockets::Server.prepend ::Sprockets::ServerWithFixedPathFingerprint
end
