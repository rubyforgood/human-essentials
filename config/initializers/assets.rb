# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

Rails.application.config.assets.precompile += %w[stimulus-loading.js]

# The Ruby for Good design system (Tailwind v4) is compiled by the tailwindcss-rails gem from
# app/assets/tailwind/application.css to app/assets/builds/tailwind.css. Sprockets serves the
# BUILD and never the source: the source uses `@import "tailwindcss"`, which Sprockets cannot
# resolve.
Rails.application.config.assets.precompile += %w[tailwind.css]
