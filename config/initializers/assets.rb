# Be sure to restart your server when you modify this file.

# Propshaft serves everything on the load path; there is no precompile list to maintain and no
# `compile`/`debug`/`digest` switches. What it does is digest filenames and rewrite the url()
# references inside CSS, which is all this app needs -- the Tailwind CLI compiles the one
# stylesheet, and importmap serves JavaScript unbundled.
#
# The load path is app/assets/* (minus the Tailwind source, excluded in application.rb),
# vendor/javascript, and whatever engines contribute.
Rails.application.config.assets.version = "1.0"
