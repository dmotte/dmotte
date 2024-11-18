#!/bin/bash

set -e

# Ensure that some variables are defined
: "${MISC_SCRIPTS_DIR:?}"

cd "$(dirname "$0")"

readonly username=${1:?} repos_dir=${2:?} badges_dir=${3:?} readme_file=${4:?}
readonly description=${5:-}

repos=$(bash "$MISC_SCRIPTS_DIR/github-get-all-repos.sh" "users/$username" \
    '.archived == false and .fork == false')
repos=$(echo "$repos" | tr -d '\r' |
    while read -r i; do echo "${i#"$username/"}"; done)

if [ ! -e "$repos_dir" ]; then
    mkdir "$repos_dir"

    (
        cd "$repos_dir"

        echo "$repos" | while read -r i; do
            git clone --depth=1 "https://github.com/$username/$i.git"
        done
    )
fi

repos_docker=()
repos_python=()
repos_rust=()
repos_vagrant=()
repos_others=()

for i in $(echo "$repos" | xargs); do
    if [ -e "$repos_dir/$i/build/Dockerfile" ]; then
        repos_docker+=("$i")
        emoji='&#x1F40B;'
    elif [ -e "$repos_dir/$i/setup.py" ]; then
        repos_python+=("$i")
        emoji='&#x1F40D;'
    elif [ -e "$repos_dir/$i/Cargo.toml" ]; then
        repos_rust+=("$i")
        emoji='&#x1F980;'
    elif [ -e "$repos_dir/$i/Vagrantfile" ]; then
        repos_vagrant+=("$i")
        emoji='&#x1F4E6;'
    else
        repos_others+=("$i")
        emoji='&#x1F4C1;'
    fi

    "$MISC_SCRIPTS_DIR/generate-badge.sh" "$emoji" "$i" > "$badges_dir/$i.svg"
done

{
    echo "# $username"
    echo
    [ -n "$description" ] && { echo "$description"; echo; }
    echo '### Docker'
    echo
    for i in "${repos_docker[@]}"; do
        echo "[![$i]($badges_dir/$i.svg)](https://github.com/$username/$i)"
    done | xargs | sed 's/ / \&nbsp; /g'
    echo
    echo '### Python'
    echo
    for i in "${repos_python[@]}"; do
        echo "[![$i]($badges_dir/$i.svg)](https://github.com/$username/$i)"
    done | xargs | sed 's/ / \&nbsp; /g'
    echo
    echo '### Rust'
    echo
    for i in "${repos_rust[@]}"; do
        echo "[![$i]($badges_dir/$i.svg)](https://github.com/$username/$i)"
    done | xargs | sed 's/ / \&nbsp; /g'
    echo
    echo '### Vagrant'
    echo
    for i in "${repos_vagrant[@]}"; do
        echo "[![$i]($badges_dir/$i.svg)](https://github.com/$username/$i)"
    done | xargs | sed 's/ / \&nbsp; /g'
    echo
    echo '### Others'
    echo
    for i in "${repos_others[@]}"; do
        echo "[![$i]($badges_dir/$i.svg)](https://github.com/$username/$i)"
    done | xargs | sed 's/ / \&nbsp; /g'
} | tee "$readme_file"

[ -z "$(git status -s)" ] || {
    echo 'There are some uncommitted changes' >&2
    git diff
    exit 1
}
