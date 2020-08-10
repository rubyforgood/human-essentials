json.extract! account_request, :id, :email, :organization_name, :organization_website, :request_details, :created_at, :updated_at
json.url account_request_url(account_request, format: :json)
