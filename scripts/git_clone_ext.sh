#!/bin/bash
# checkout_git_ref REPO_URL DEST REF
# Shallow-clone main, then detach checkout a tag, branch, or commit SHA.
set -euo pipefail

repo_url="$1"
dest="$2"
ref="$3"

git clone --depth 1 --branch main "$repo_url" "$dest"
cd "$dest"

if [ "$ref" = "main" ]; then
    echo "Checked out git ref: main"
    git log -1
    exit 0
fi

if git fetch --depth 1 origin "refs/tags/${ref}:refs/tags/${ref}" 2>/dev/null \
    && git rev-parse "refs/tags/${ref}" >/dev/null 2>&1; then
    git checkout --detach "refs/tags/${ref}"
    git log -1
    echo "Checked out git ref: ${ref}"
elif git fetch --depth 1 origin "${ref}"; then
    git checkout --detach "${ref}"
    git log -1
    echo "Checked out git ref: ${ref}"
else
    git log -1
    echo "Unable to fetch git ref: ${ref}" >&2
    exit 1
fi
