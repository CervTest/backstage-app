#!/bin/bash

# Change working directory to the directory where this script is located
cd "$(dirname "$0")"

# Input template files
env_common_template="env.common.template"
env_client_template="env.instance.template"
output_file="../.env"

# Check if .env file exists
if [ -f "$output_file" ]; then
  # .env file exists, use it as a base
  cp "$output_file" "$output_file.tmp"
else
  # .env file doesn't exist, use the common template
  cp "$env_common_template" "$output_file.tmp"
fi

# Merge both common and client templates, overwriting existing keys and adding new ones
merge_templates() {
  local template_file="$1"
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip lines starting with #
    if [[ $line == \#* ]]; then
      continue
    fi

    key=$(echo "$line" | cut -d'=' -f1)
    grep -q "^$key=" "$output_file.tmp" && awk -v key="$key" -v line="$line" -F= '$1 == key {$0 = line} 1' "$output_file.tmp" > "$output_file.tmp2" && mv "$output_file.tmp2" "$output_file.tmp" || echo "$line" >> "$output_file.tmp"
  done < "$template_file"
}

# Merge the common template
merge_templates "$env_common_template"

# Merge the client template
merge_templates "$env_client_template"

# Set the TOKEN key in .env
awk -v token="$(yarn -s token)" '{gsub(/{TOKEN}/, token)}1' "$output_file.tmp" > "$output_file.tmp2"

# Remove extra newlines
awk 'NF {print; blank=0} /^$/ {blank++} {if (blank > 2) blank=2} END {if (blank > 1) exit}' "$output_file.tmp2" > "$output_file"

rm -f "$output_file.tmp"
rm -f "$output_file.tmp2"

# Also copy the config file templates
cp "app-config.env.local.template.yaml" "../app-config.env.local.yaml"
cp "app-config.instance.template.yaml" "../app-config.instance.yaml"

# Exit with success status
exit 0
