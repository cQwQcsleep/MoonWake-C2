#!/bin/bash
# Generate the build matrix from configs/<type>/.
#
# Inputs (env): CONFIG_FILE_IN, CONFIG_TYPE_IN, GITHUB_OUTPUT
# Outputs (GITHUB_OUTPUT): repos (matrix JSON), buildfile (human readable)
#
# Batch mode enumerates every *.json in the config dir and skips entries marked
# "deprecated": true, so a quarantined config can never be released by accident.
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE_IN:-}"
CONFIG_TYPE="${CONFIG_TYPE_IN:-release}"
CONFIG_DIR="configs/$CONFIG_TYPE"

emit() {
    {
        echo "buildfile=$1"
        echo 'repos<<EOF'
        echo "$2"
        echo 'EOF'
    } >> "$GITHUB_OUTPUT"
}

names_of() {
    jq -r '[.[].kernelSource.name] | join(", ")' <<< "$1"
}

validate() {
    sed -i '1s/^\xEF\xBB\xBF//' "$1"
    jq empty "$1" >/dev/null 2>&1 || {
        echo "ERROR: invalid JSON: $1" >&2
        jq '.' "$1" || true
        exit 1
    }
}

is_deprecated() {
    [ "$(jq -r 'map(.deprecated // false) | any' "$1")" = true ]
}

echo "config type: $CONFIG_TYPE  requested file: [${CONFIG_FILE}]"

if [ -n "$CONFIG_FILE" ]; then
    path="$CONFIG_DIR/$CONFIG_FILE"
    [ -f "$path" ] || { echo "ERROR: $path does not exist" >&2; exit 1; }
    validate "$path"
    if is_deprecated "$path"; then
        echo "WARNING: $path is marked deprecated; building because it was requested explicitly" >&2
    fi
    matrix="$(jq -s '[.[][]]' "$path")"
    emit "$CONFIG_FILE ($(names_of "$matrix"))" "$matrix"
    echo "using $path => $(names_of "$matrix")"
    exit 0
fi

selected=''
skipped=''
while IFS= read -r cfg; do
    [ -n "$cfg" ] || continue
    validate "$cfg"
    if is_deprecated "$cfg"; then
        echo "[-] skip deprecated: $cfg"
        skipped="$skipped $cfg"
        continue
    fi
    echo "[+] build: $cfg"
    selected="$selected $cfg"
done < <(find "$CONFIG_DIR" -type f -name '*.json' | LC_ALL=C sort)

[ -n "$selected" ] || { echo "ERROR: no non-deprecated config in $CONFIG_DIR/" >&2; exit 1; }

matrix='[]'
for cfg in $selected; do
    matrix="$(jq -s 'add' <(echo "$matrix") "$cfg")"
done

echo "not built (deprecated):${skipped:- none}"
echo "building: $(names_of "$matrix")"
emit "all configs ($(names_of "$matrix"))" "$matrix"
