require 'open3'

sha, _, status = Open3.capture3('git rev-parse HEAD')
if status.exitstatus == 128
  `git config --global --add safe.directory #{Rails.root}`
  sha = `git rev-parse HEAD`
end
ENV['GIT_SHA'] = sha

