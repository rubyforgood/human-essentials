module Partner
  class Client
    API_KEY = "secretpartnerkey".freeze

    def call
      response = RestClient::Request.execute(method: :get,
                                             url: "https://partner.diaper.app/api/v1/partners/1",
                                             headers: { "X-Api-Key" => API_KEY })
      if response.code = 200
        _response = JSON.parse response.body
      end
    end
  end
end
