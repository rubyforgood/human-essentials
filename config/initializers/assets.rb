# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

Rails.application.config.assets.precompile += %w(stimulus-loading.js bootstrap.min.js popper.js)

# The Ruby for Good design system (Tailwind v4) is compiled by the tailwindcss-rails gem
# from app/assets/tailwind/application.css to app/assets/builds/tailwind.css. Sprockets
# must serve the BUILD and never the source, which uses `@import "tailwindcss"` and would
# raise if Sprockets tried to process it.
#
# Note that the gem hardcodes its input path, so `app/assets/tailwind/application.css`
# shares a logical name with the Bootstrap manifest at
# `app/assets/stylesheets/application.scss`. `application.css` resolves to the Bootstrap
# one because Sprockets appends `app/assets/*` in directory order and "stylesheets" sorts
# before "tailwind". That is stable but implicit, so it is pinned by
# spec/assets/asset_resolution_spec.rb -- if it ever flips, every Bootstrap page in the
# app loses its stylesheet at once.
Rails.application.config.assets.precompile += %w(tailwind.css)
