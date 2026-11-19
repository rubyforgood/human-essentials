# A Sprockets CSS compressor that leaves the Tailwind build alone.
#
# sassc-rails defaults `config.assets.css_compressor` to `:sass` in every environment except
# development, so production, staging and test minify every stylesheet with libsass. libsass
# cannot parse the CSS that Tailwind v4 emits (oklch(), color-mix(), @property, nested @layer)
# and raises -- which in production means `assets:precompile` fails and the deploy with it.
#
# The Tailwind CLI already minifies its own output, so the build needs no second pass. Every
# other stylesheet is handed to the same Sass compressor as before, byte for byte.
#
# Delete this, and the `css_compressor` line in config/application.rb, when Sass leaves the app.
class TailwindSafeCssCompressor
  TAILWIND_BUILD = "tailwind".freeze

  def self.call(input)
    return input[:data] if input[:name] == TAILWIND_BUILD

    Sprockets::SassCompressor.call(input)
  end
end
