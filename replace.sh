#!/usr/bin/env bash

# Check if a directory is provided as an argument
if [ $# -ne 1 ]; then
	echo "Usage: $0 <directory>"
	exit 1
fi

# Store the directory provided as an argument
directory="$1"

# Check if the provided directory exists
if [ ! -d "$directory" ]; then
	echo "Error: $directory is not a valid directory."
	exit 1
fi

# Find all files in the directory and its subdirectories ending with _spec.rb
find "$directory" -type f -name "*_spec.rb" | while read -r file; do
	# Perform the replacements using sed
  sed -i 's/RSpec.describe \(.*\) do/RSpec.describe \1 do\n  let(:organization) { create(:organization, skip_items: true) }\n  let(:user) { create(:user, organization: organization) }\n  let(:organization_admin) { create(:organization_admin, organization: organization) }\n/g' "$file"
  sed -i 's/@organization_admin/organization_admin/g' "$file"
  sed -i 's/@organization/organization/g' "$file"
  sed -i 's/@user/user/g' "$file"

done

echo "Script executed on all *_spec.rb files in $directory and its subdirectories."
