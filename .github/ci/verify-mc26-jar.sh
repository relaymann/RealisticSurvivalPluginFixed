#!/usr/bin/env bash
set -euo pipefail

shopt -s nullglob
jars=(target/realisticsurvival-*-mc26.jar)
if [[ ${#jars[@]} -ne 1 ]]; then
  echo "Expected exactly one Minecraft 26 JAR in target/, found ${#jars[@]}." >&2
  printf 'Found: %s\n' "${jars[@]:-<none>}" >&2
  exit 1
fi

jar_file="${jars[0]}"
if [[ ! -s "$jar_file" ]]; then
  echo "Compatibility JAR is missing or empty: $jar_file" >&2
  exit 1
fi

contents="$(mktemp)"
trap 'rm -f "$contents"' EXIT
jar tf "$jar_file" > "$contents"

require_entry() {
  if ! grep -Fxq -- "$1" "$contents"; then
    echo "Required class/resource missing from $jar_file: $1" >&2
    exit 1
  fi
}

# Plugin bootstrap plus Paper 26.1.2's NMS provider and every custom mob type.
require_entry "plugin.yml"
require_entry "me/val_mobile/rsv/RSVPlugin.class"
require_entry "me/val_mobile/utils/v26_1_R3.class"
require_entry "me/val_mobile/utils/CustomEntities_v26_1_R3.class"
require_entry "me/val_mobile/utils/FireDragon_v26_1_R3.class"
require_entry "me/val_mobile/utils/IceDragon_v26_1_R3.class"
require_entry "me/val_mobile/utils/LightningDragon_v26_1_R3.class"
require_entry "me/val_mobile/utils/SeaSerpent_v26_1_R3.class"
require_entry "me/val_mobile/utils/Siren_v26_1_R3.class"
require_entry "me/val_mobile/iceandfire/IceFireModule.class"

metadata="$(unzip -p "$jar_file" plugin.yml)"
grep -Fxq "main: me.val_mobile.rsv.RSVPlugin" <<< "$metadata"
grep -Fxq "version: 1.2.9-RELEASE" <<< "$metadata"

echo "Compatibility JAR contents validated: $jar_file"
du -h "$jar_file"
sha256sum "$jar_file"
