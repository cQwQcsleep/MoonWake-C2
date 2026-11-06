#!/bin/sh
# MoonWake formal kernel version string.
# Runs inside the kernel source tree; KERNEL_NAME is the CI config name,
# e.g. "MoonWake-2.7.0-C1V".
name="${KERNEL_NAME:-}"
suffix="${name#MoonWake-2.7.0-}"

if [ -n "$suffix" ] && [ "$suffix" != "$name" ]; then
    printf -- '-MoonWake-2.7.0-%s\n' "$suffix" > localversion-moon
else
    printf -- '-MoonWake-2.7.0\n' > localversion-moon
fi

echo "localversion-moon: $(cat localversion-moon)"
