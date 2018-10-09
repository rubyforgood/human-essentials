Geocoder.configure(lookup: :test)

Geocoder::Lookup::Test.set_default_stub(
  [
    {
      "coordinates"  => [40.7143528, -74.0059731],
      "address"      => "New York, NY, USA",
      "state"        => "New York",
      "state_code"   => "NY",
      "country"      => "United States",
      "country_code" => "US"
    }
  ]
)

Geocoder::Lookup::Test.add_stub(
  "New York, NY", [
    {
      "coordinates"  => [40.7143528, -74.0059731],
      "address"      => "New York, NY, USA",
      "state"        => "New York",
      "country"      => "United States",
      "country_code" => "US"
    }
  ]
)

Geocoder::Lookup::Test.add_stub(
  "Washington, DC", [
    {
      "coordinates"  => [38.8950092, -77.0365625],
      "address"      => "Washington, DC, USA",
      "state"        => "District of Columbia",
      "country"      => "United States",
      "country_code" => "US"
    }
  ]
)

Geocoder::Lookup::Test.add_stub(
  "Des Moines, Iowa", [
    "coordinates" => [41.5910641, -93.6037149],
    "address"         =>   "Des Moines, Polk County, Iowa, USA",
    "city"            =>   "Des Moines",
    "State/province"  =>   "Iowa"

  ]
)

Geocoder::Lookup::Test.add_stub(
  "1500 Remount Road, Front Royal, VA", [
    "coordinates" => [38.8876919, -78.1659477],
    "address"         =>   "1500 Remount Road, Front Royal, VA, USA",
    "city"            =>   "Front Royal",
    "State/province"  =>   "VA",
    "country"         => "United States",
    "country_code"    => "US"
  ]
)
