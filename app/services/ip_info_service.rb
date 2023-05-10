class IpInfoService
  def self.get_timezone
    response = Faraday.get("https://ipinfo.io/json")
    body = JSON.parse(response.body, symbolize_names: true)
    body[:timezone]
  end
end
