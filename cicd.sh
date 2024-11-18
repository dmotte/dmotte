#!/bin/bash

set -e

# Ensure that some variables are defined
: "${MISC_SCRIPTS_DIR:?}"

cd "$(dirname "$0")"

repos=$(bash "$MISC_SCRIPTS_DIR/github-get-all-repos.sh" users/dmotte \
    '.archived == false and .fork == false')
repos=$(echo "$repos" | tr -d '\r')

# mkdir repos

# (
#     cd repos

#     echo "$repos" | while read -r i; do
#         git clone --depth=1 "https://github.com/$i.git"
#     done
# )

repos_docker=()
repos_python=()
repos_rust=()
repos_vagrant=()
repos_others=()

for i in $(echo "$repos" | xargs); do
    name=$(basename "$i")

    [ -e "repos/$name/build/Dockerfile" ] && { repos_docker+=("$name"); continue; }
    [ -e "repos/$name/setup.py" ] && { repos_python+=("$name"); continue; }
    [ -e "repos/$name/Cargo.toml" ] && { repos_rust+=("$name"); continue; }
    [ -e "repos/$name/Vagrantfile" ] && { repos_vagrant+=("$name"); continue; }

    repos_others+=("$name")
done

mkdir -p badges # TODO remove "-p"

{
    echo '# Title here'
    echo
    echo '### Docker'
    echo
    for i in "${repos_docker[@]}"; do
        "$MISC_SCRIPTS_DIR/generate-badge.sh" '&#x1F40B;' "$i" > "badges/$i.svg"
        echo -n "![$i](badges/$i.svg) &nbsp; "
    done; echo
    echo
    echo '### Python'
    echo
    for i in "${repos_python[@]}"; do
        "$MISC_SCRIPTS_DIR/generate-badge.sh" '&#x1F40D;' "$i" > "badges/$i.svg"
        echo -n "![$i](badges/$i.svg) &nbsp; "
    done; echo
    echo
    echo '### Rust'
    echo
    for i in "${repos_rust[@]}"; do
        "$MISC_SCRIPTS_DIR/generate-badge.sh" '&#x1F980;' "$i" > "badges/$i.svg"
        echo -n "![$i](badges/$i.svg) &nbsp; "
    done; echo
    echo
    echo '### Vagrant'
    echo
    for i in "${repos_vagrant[@]}"; do
        "$MISC_SCRIPTS_DIR/generate-badge.sh" '&#x1F4E6;' "$i" > "badges/$i.svg"
        echo -n "![$i](badges/$i.svg) &nbsp; "
    done; echo
    echo
    echo '### Others'
    echo
    for i in "${repos_others[@]}"; do
        "$MISC_SCRIPTS_DIR/generate-badge.sh" '&#x1F4C1;' "$i" > "badges/$i.svg"
        echo -n "![$i](badges/$i.svg) &nbsp; "
    done; echo
} > README.md

# TODO add links to the images in the README
