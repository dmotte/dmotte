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

repos_docker=
repos_python=
repos_rust=
repos_vagrant=
repos_others=

for i in $(echo "$repos" | xargs); do
    if [ -e "$repos_dir/$i/build/Dockerfile" ]; then
        repos_docker+="$i"$'\n'
        emoji='&#x1F40B;'
    elif [ -e "$repos_dir/$i/setup.py" ]; then
        repos_python+="$i"$'\n'
        emoji='&#x1F40D;'
    elif [ -e "$repos_dir/$i/Cargo.toml" ]; then
        repos_rust+="$i"$'\n'
        emoji='&#x1F980;'
    elif [ -e "$repos_dir/$i/Vagrantfile" ]; then
        repos_vagrant+="$i"$'\n'
        emoji='&#x1F4E6;'
    else
        repos_others+="$i"$'\n'
        emoji='&#x1F4C1;'
    fi

    bash "$MISC_SCRIPTS_DIR/generate-badge.sh" "$emoji" "$i" 1f2328 \
        > "$badges_dir/light-$i.svg"
    bash "$MISC_SCRIPTS_DIR/generate-badge.sh" "$emoji" "$i" f0f6fc \
        > "$badges_dir/dark-$i.svg"
done

generate_badges() {
    while read -r i; do
        echo -n '<a href="'"https://github.com/$username/$i"'">'

        echo -n '<picture>'
        echo -n '<source media="(prefers-color-scheme: dark)"' \
            'srcset="'"$badges_dir/dark-$i.svg"'">'
        echo -n '<source media="(prefers-color-scheme: light)"' \
            'srcset="'"$badges_dir/light-$i.svg"'">'
        echo -n '<img alt="'"$i"'" src="'"$badges_dir/light-$i.svg"'">'
        echo -n '</picture>'

        echo -n '</a>'

        echo -n '&nbsp;'
    done

    echo
}

{
    echo "# $username"
    echo
    [ -n "$description" ] && { echo "$description"; echo; }
    echo '### Docker'
    echo
    echo -n "$repos_docker" | generate_badges
    echo
    echo '### Python'
    echo
    echo -n "$repos_python" | generate_badges
    echo
    echo '### Rust'
    echo
    echo -n "$repos_rust" | generate_badges
    echo
    echo '### Vagrant'
    echo
    echo -n "$repos_vagrant" | generate_badges
    echo
    echo '### Others'
    echo
    echo -n "$repos_others" | generate_badges
    echo
    echo '> **Note**: this content was **automatically generated** by a' \
        '[**custom script**](https://github.com/dmotte/dmotte/blob/main/cicd.sh).'
} | tee "$readme_file"

[ -z "$(git status -s)" ] || {
    echo 'There are some uncommitted changes' >&2
    git diff
    exit 1
}
