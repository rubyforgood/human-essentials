# The lights on the landing page's map: one for each BankListing with a location, placed on the
# outline of the United States drawn in `static/_bank_map`.
#
# The outline is a fixed drawing and the lights are not. BankListingImportService replaces the
# listings every week, so the positions are worked out here on each request rather than drawn
# once -- a map that says "347 banks" under 347 dots would be wrong the first Sunday a bank
# joined a directory. There are a few hundred listings and the arithmetic is a dozen
# trigonometric calls each, so nothing is cached.
#
# The projection is Albers USA, the composite that d3-geo calls `geoAlbersUsa`: an Albers conic
# for the lower 48 states, with Alaska (at 0.35 scale) and Hawaii set into the bottom left
# corner. It is written out here because the outline was drawn with d3 at `scale(1280)` and
# `translate([480, 300])` on a 960 by 600 canvas, and a light only sits on its city if both use
# the same numbers. The spec pins points d3 produced.
class BankMapQuery
  WIDTH = 960
  HEIGHT = 600

  # Puerto Rico is outside all three projections, so its banks get a labelled spot of their own
  # in the open water south-east of Florida, which is roughly where the island is.
  PUERTO_RICO = [900.0, 558.0].freeze
  PUERTO_RICO_SPACING = 9.0

  # `kind` is the CSS class that colours the light: d(iapers), p(eriod supplies) or b(oth).
  Light = Data.define(:x, :y, :kind)

  # `as_of` is when the listings were last imported. `puerto_rico` says whether to draw its label.
  Map = Data.define(:lights, :as_of, :puerto_rico) do
    def count = lights.size

    def any? = lights.any?
  end

  def self.call
    rows = BankListing.located.pluck(:latitude, :longitude, :state, :diapers, :period_supplies)
    Map.new(lights: lights_for(rows), as_of: BankListing.maximum(:updated_at),
      puerto_rico: rows.any? { |row| row[2] == "PR" })
  end

  # East to west, which is the order the page turns them on: the way a morning arrives.
  def self.lights_for(rows)
    islanders, mainlanders = rows.partition { |row| row[2] == "PR" }

    lights = mainlanders.filter_map do |latitude, longitude, _state, diapers, period_supplies|
      x, y = AlbersUsa.point(latitude, longitude)
      Light.new(x: x.round(1), y: y.round(1), kind: kind(diapers, period_supplies)) if x
    end

    islanders.each_with_index do |(_lat, _lon, _state, diapers, period_supplies), index|
      offset = (index - (islanders.size - 1) / 2.0) * PUERTO_RICO_SPACING
      lights << Light.new(x: (PUERTO_RICO[0] + offset).round(1), y: PUERTO_RICO[1], kind: kind(diapers, period_supplies))
    end

    lights.sort_by { |light| [-light.x, light.y] }
  end

  def self.kind(diapers, period_supplies)
    if diapers && period_supplies
      "b"
    elsif period_supplies
      "p"
    else
      "d"
    end
  end

  # d3-geo's geoAlbersUsa, for points only. Returns [x, y], or nil for somewhere none of the
  # three projections draws (Puerto Rico, Guam, a coordinate that is simply wrong).
  module AlbersUsa
    RADIANS = Math::PI / 180
    EPSILON = 1e-6
    SCALE = 1280.0
    CENTER_X = WIDTH / 2.0
    CENTER_Y = HEIGHT / 2.0

    # One Albers equal-area conic: d3's `conicEqualArea().parallels().rotate().center()`.
    class Conic
      # `clip` is the rectangle this projection owns, as fractions of SCALE from the centre:
      # [left, top, right, bottom].
      def initialize(parallels:, rotate:, center:, scale:, offset:, clip:, inset: 0)
        sin0 = Math.sin(parallels[0] * RADIANS)
        @n = (sin0 + Math.sin(parallels[1] * RADIANS)) / 2
        @c = 1 + sin0 * (2 * @n - sin0)
        @r0 = Math.sqrt(@c) / @n
        @rotate = rotate * RADIANS
        @scale = scale

        # d3 places `center` -- given relative to the rotation, not as a longitude -- at the
        # translation point.
        centre_x, centre_y = raw(center[0] * RADIANS, center[1] * RADIANS)
        @dx = CENTER_X + offset[0] * SCALE - centre_x * @scale
        @dy = CENTER_Y + offset[1] * SCALE + centre_y * @scale

        @left = CENTER_X + clip[0] * SCALE + inset
        @top = CENTER_Y + clip[1] * SCALE + inset
        @right = CENTER_X + clip[2] * SCALE - inset
        @bottom = CENTER_Y + clip[3] * SCALE - inset
      end

      def point(latitude, longitude)
        lambda = longitude * RADIANS + @rotate
        lambda -= 2 * Math::PI while lambda > Math::PI
        lambda += 2 * Math::PI while lambda < -Math::PI

        raw_x, raw_y = raw(lambda, latitude * RADIANS)
        x = @dx + @scale * raw_x
        y = @dy - @scale * raw_y
        [x, y] if x.between?(@left, @right) && y.between?(@top, @bottom)
      end

      private

      def raw(lambda, phi)
        r = Math.sqrt(@c - 2 * @n * Math.sin(phi)) / @n
        [r * Math.sin(lambda * @n), @r0 - r * Math.cos(lambda * @n)]
      end
    end

    # Tried in this order, as d3 does. The lower 48's rectangle is the whole canvas, which is
    # safe because Alaska and Hawaii projected with its numbers land far outside it.
    PROJECTIONS = [
      Conic.new(parallels: [29.5, 45.5], rotate: 96, center: [-0.6, 38.7], scale: SCALE,
        offset: [0, 0], clip: [-0.455, -0.238, 0.455, 0.238]),
      Conic.new(parallels: [55, 65], rotate: 154, center: [-2, 58.5], scale: SCALE * 0.35,
        offset: [-0.307, 0.201], clip: [-0.425, 0.120, -0.214, 0.234], inset: EPSILON),
      Conic.new(parallels: [8, 18], rotate: 157, center: [-3, 19.9], scale: SCALE,
        offset: [-0.205, 0.212], clip: [-0.214, 0.166, -0.115, 0.234], inset: EPSILON)
    ].freeze

    def self.point(latitude, longitude)
      PROJECTIONS.each do |projection|
        found = projection.point(latitude, longitude)
        return found if found
      end
      nil
    end
  end
end
