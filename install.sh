#!/usr/bin/env bash
set -euo pipefail

source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy"
target_dir="$config_dir/plugins/rasp.power"
config_file="$config_dir/shell.json"
for tool in jq omarchy omarchy-shell; do
  command -v "$tool" >/dev/null || { echo "Missing command: $tool" >&2; exit 1; }
done
[[ -f $config_file ]] || { echo "Missing $config_file" >&2; exit 1; }
omarchy-shell shell ping >/dev/null
if [[ -x /usr/lib/qt6/bin/qmlformat ]]; then
  /usr/lib/qt6/bin/qmlformat "$source_dir/Panel.qml" >/dev/null
fi
jq -e '.id == "rasp.power" and .omarchy.clonedFrom == "omarchy.power"' \
  "$source_dir/manifest.json" >/dev/null
backup_dir=$(mktemp -d "$config_dir/power-widget-backup.XXXXXX")
cp -a "$config_file" "$backup_dir/shell.json"
if [[ -d $target_dir ]]; then cp -a "$target_dir" "$backup_dir/rasp.power"; fi
mkdir -p "$target_dir"
for file in Panel.qml Model.js Boost.js manifest.json; do
  install -m 644 "$source_dir/$file" "$target_dir/$file"
done
echo "Backup: $backup_dir"
omarchy-shell shell rescanPlugins >/dev/null
omarchy plugin enable rasp.power
# A restart also clears failed components cached by an earlier installation.
omarchy restart shell
echo "Installed Power + CPU Boost. Click the power icon to open it."
