json.array!(@pick_ups) do |pickup|
  json.set! :id, pickup.id
  json.set! :title, pickup.partner.name
  json.set! :description, pickup.comment
  json.set! :className, pickup.complete? ? 'fc-dist-complete' : 'fc-dist-scheduled'
  json.start pickup.issued_at
  json.end pickup.issued_at
  json.url pickup_day_distributions_path(filters: { during: pickup.issued_at.to_date })
end