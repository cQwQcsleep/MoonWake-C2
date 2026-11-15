#!/bin/bash
# Fetch every toolchain declared in the config's toolchains[] block.
#
# Inputs (env): toolchains (toolchains JSON array), GITHUB_WORKSPACE, GITHUB_PATH
set -euo pipefail

num="$(jq 'length' <<< "$toolchains")"
echo "There are $num defined toolchains."

for ((i = 0; i < num; i++)); do
    name="$(jq -r ".[$i].name" <<< "$toolchains")"
    repo="$(jq -r ".[$i].repo // empty" <<< "$toolchains")"
    branch="$(jq -r ".[$i].branch // empty" <<< "$toolchains")"
    url="$(jq -r ".[$i].url // empty" <<< "$toolchains")"

    echo "Processing toolchain: $name"

    if [ -z "$url" ]; then
        [ -n "$repo" ] || { echo "ERROR: toolchain $name has neither repo nor url" >&2; exit 1; }
        ok=0
        for attempt in 1 2 3; do
            if git clone --recursive --depth=1 -j "$(nproc)" --branch "$branch" "$repo" "$name"; then
                ok=1
                break
            fi
            echo "Retrying git clone ($attempt/3)..."
            sleep 5
        done
        [ "$ok" = 1 ] || { echo "ERROR: git clone failed after 3 attempts: $repo" >&2; exit 1; }
    else
        file="${url##*/}"
        ok=0
        for attempt in 1 2 3; do
            if aria2c --summary-interval=0 --console-log-level=info -x 16 -s 16 -o "$file" "$url"; then
                ok=1
                break
            fi
            echo "Retrying download ($attempt/3)..."
            sleep 5
        done
        [ "$ok" = 1 ] || { echo "ERROR: download failed after 3 attempts: $url" >&2; exit 1; }

        mkdir -p "$name"
        case "$file" in
            *.zip) unzip -q -d "$name" "$file" ;;
            *.tar) tar xf "$file" -C "$name" ;;
            *.tar.gz|*.tgz) tar zxf "$file" -C "$name" ;;
            *.rar) unrar x "$file" "$name" ;;
            *) echo "ERROR: unknown archive type: $file" >&2; exit 1 ;;
        esac
    fi

    while IFS= read -r bin_path; do
        echo "${GITHUB_WORKSPACE:-$PWD}/$name/$bin_path" >> "$GITHUB_PATH"
    done < <(jq -r ".[$i].binPath[] | tostring" <<< "$toolchains")
done
