json.array!(@pick_ups) do |pickup|
  json.set! :id, pickup.id
  json.set! :title, pickup.partner.name
  json.set! :description, pickup.comment
  json.start pickup.issued_at
  json.end pickup.issued_at
  json.url distribution_url(pickup)
end