#!/usr/bin/env bash
# readlink-portable.sh - Cross-platform symlink resolution
#
# Usage:
#   source readlink-portable.sh
#   realpath_portable <path>
#   readlink_portable <path>
#
# Description:
#   Provides portable realpath functionality for resolving symlinks
#   across different operating systems (Linux, macOS, BSD).

set -euo pipefail

# Get canonical path (resolve all symlinks)
# Args:
#   $1 - Path to resolve
# Returns:
#   Canonical path on stdout, or original path if resolution fails
realpath_portable() {
    local path="$1"

    # Try native realpath first (Linux, newer macOS)
    if command -v realpath >/dev/null 2>&1; then
        realpath "$path" 2>/dev/null && return 0
    fi

    # Try readlink -f (Linux)
    if readlink -f "$path" 2>/dev/null; then
        return 0
    fi

    # Try greadlink -f (macOS with coreutils)
    if command -v greadlink >/dev/null 2>&1; then
        greadlink -f "$path" 2>/dev/null && return 0
    fi

    # Python fallback (works on all platforms with Python)
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$path" 2>/dev/null && return 0
    fi

    if command -v python >/dev/null 2>&1; then
        python -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$path" 2>/dev/null && return 0
    fi

    # Fallback: try manual resolution
    resolve_symlinks_manual "$path"
}

# Manually resolve symlinks (fallback method)
# Args:
#   $1 - Path to resolve
# Returns:
#   Resolved path on stdout
resolve_symlinks_manual() {
    local path="$1"
    local max_depth=50
    local depth=0

    # Make path absolute if relative
    if [[ "$path" != /* ]]; then
        path="$(pwd)/$path"
    fi

    # Resolve symlinks iteratively
    while [[ -L "$path" ]] && [[ $depth -lt $max_depth ]]; do
        local target
        target=$(readlink "$path" 2>/dev/null) || break

        # Make target absolute if relative
        if [[ "$target" != /* ]]; then
            local dir
            dir=$(dirname "$path")
            target="$dir/$target"
        fi

        path="$target"
        ((depth++))
    done

    # Normalize path (remove ., .., etc.)
    normalize_path "$path"
}

# Normalize path by removing . and .. components
# Args:
#   $1 - Path to normalize
# Returns:
#   Normalized path on stdout
normalize_path() {
    local path="$1"

    # Use Python if available (most reliable)
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "import os,sys; print(os.path.normpath(sys.argv[1]))" "$path" && return 0
    fi

    if command -v python >/dev/null 2>&1; then
        python -c "import os,sys; print(os.path.normpath(sys.argv[1]))" "$path" && return 0
    fi

    # Fallback: basic normalization with sed
    echo "$path" | sed -e 's|/\./|/|g' -e 's|/\+|/|g' -e 's|/$||'
}

# Read symlink target (one level only)
# Args:
#   $1 - Symlink path
# Returns:
#   Target path on stdout (may be relative)
readlink_portable() {
    local path="$1"

    # Use readlink if available
    if readlink "$path" 2>/dev/null; then
        return 0
    fi

    # Try ls -l parsing (POSIX fallback)
    if [[ -L "$path" ]]; then
        ls -l "$path" | sed -n 's/.* -> //p'
        return 0
    fi

    # Not a symlink or failed
    return 1
}

# Check if path is a symlink
# Args:
#   $1 - Path to check
# Returns:
#   0 if symlink, 1 otherwise
is_symlink() {
    local path="$1"
    [[ -L "$path" ]]
}

# Get absolute path without resolving symlinks
# Args:
#   $1 - Path
# Returns:
#   Absolute path on stdout
get_absolute_path() {
    local path="$1"

    # If already absolute, normalize and return
    if [[ "$path" = /* ]]; then
        normalize_path "$path"
        return 0
    fi

    # Make relative path absolute
    normalize_path "$(pwd)/$path"
}

# Get directory of canonical path
# Args:
#   $1 - Path
# Returns:
#   Canonical directory path on stdout
get_canonical_dir() {
    local path="$1"
    local canonical

    canonical=$(realpath_portable "$path")
    dirname "$canonical"
}

# Compare two paths (canonical comparison)
# Args:
#   $1 - First path
#   $2 - Second path
# Returns:
#   0 if paths point to same location, 1 otherwise
paths_equal() {
    local path1="$1"
    local path2="$2"

    local canonical1
    local canonical2

    canonical1=$(realpath_portable "$path1")
    canonical2=$(realpath_portable "$path2")

    [[ "$canonical1" == "$canonical2" ]]
}

# Export functions for use in other scripts
export -f realpath_portable
export -f resolve_symlinks_manual
export -f normalize_path
export -f readlink_portable
export -f is_symlink
export -f get_absolute_path
export -f get_canonical_dir
export -f paths_equal
