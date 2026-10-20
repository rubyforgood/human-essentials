# The banks nearest a CensusLocation::Point, closest first, for the public bank finder.
#
# Distances are great-circle miles between headquarters cities: the directories give no
# addresses, so anything more exact would be false precision. There are a few hundred listings,
# so they are measured in Ruby rather than in SQL. See ADR 0014.
class NearbyBanksQuery
  # Within this, a bank counts as "near". Past it, the page says nothing is near and still
  # shows the closest, because many banks serve a whole region.
  NEAR_MILES = 50
  LIMIT = 8
  EARTH_RADIUS_MILES = 3958.8

  Result = Data.define(:listing, :miles)

  def self.call(point, limit: LIMIT)
    BankListing.located.map { |listing| Result.new(listing:, miles: miles_between(point, listing)) }
      .sort_by { |r| [r.miles, r.listing.name] }
      .first(limit)
  end

  def self.miles_between(a, b)
    lat1, lon1, lat2, lon2 = [a.latitude, a.longitude, b.latitude, b.longitude].map { |d| d * Math::PI / 180 }
    h = Math.sin((lat2 - lat1) / 2)**2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin((lon2 - lon1) / 2)**2
    2 * EARTH_RADIUS_MILES * Math.asin(Math.sqrt(h))
  end
end
