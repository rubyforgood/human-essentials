ENV['GIT_SHA'] = File.read(File.join(Rails.root, "REVISION")).strip if File.exist?(File.join(Rails.root, "REVISION"))
