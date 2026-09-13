#!/bin/bash

set -euo pipefail

root=$(mktemp -d "${TMPDIR:-/tmp}/dev-sync-test.XXXXXX")
trap 'rm -rf "$root"' EXIT

home_dir="$root/home"
work_root="$home_dir/work"
bin_dir="$root/bin"
dotfiles_repo="$root/dotfiles"
mkdir -p "$home_dir/.config" "$work_root" "$bin_dir"

printf '%s\n' \
    '@chezmoi|example/dotfiles|write' \
    'work/write-repo|example/write|write' \
    'work/read-repo|example/read|read' \
    > "$home_dir/.config/dev-repos.tsv"

for repo_name in dotfiles write-repo read-repo; do
    bare_repo="$root/$repo_name.git"
    if [[ "$repo_name" == "dotfiles" ]]; then
        work_repo="$dotfiles_repo"
    else
        work_repo="$work_root/$repo_name"
    fi
    git -c init.defaultBranch=main init --bare "$bare_repo" >/dev/null
    git -c init.defaultBranch=main init "$work_repo" >/dev/null
    git -C "$work_repo" config user.email test@example.com
    git -C "$work_repo" config user.name Test
    git -C "$work_repo" config commit.gpgsign false
    touch "$work_repo/README.md"
    git -C "$work_repo" add README.md
    git -C "$work_repo" commit -m init >/dev/null
    git -C "$work_repo" remote add origin "$bare_repo"
    git -C "$work_repo" push -u origin main >/dev/null
done

cat > "$bin_dir/chezmoi" <<EOF
#!/bin/bash
case "\$1" in
    source-path) printf '%s\n' '$dotfiles_repo' ;;
    apply) touch '$root/chezmoi-applied' ;;
    *) exit 2 ;;
esac
EOF
chmod +x "$bin_dir/chezmoi"

cat > "$bin_dir/codex" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >> "$CODEX_LOG"
EOF
chmod +x "$bin_dir/codex"

test_path="$bin_dir:$PATH"

HOME="$home_dir" DEV_HOME_ROOT="$home_dir" DEV_WORK_ROOT="$work_root" PATH="$test_path" \
    /bin/bash bin/executable_dev-sync status >/dev/null

printf '%s' dirty >> "$work_root/read-repo/README.md"
write_head=$(git -C "$work_root/write-repo" rev-parse HEAD)

set +e
HOME="$home_dir" DEV_HOME_ROOT="$home_dir" DEV_WORK_ROOT="$work_root" PATH="$test_path" \
    /bin/bash bin/executable_dev-sync pull >/dev/null 2>&1
pull_exit=$?
set -e

[[ "$pull_exit" -eq 1 ]]
[[ "$(git -C "$work_root/write-repo" rev-parse HEAD)" == "$write_head" ]]

git -C "$work_root/read-repo" restore README.md
HOME="$home_dir" DEV_HOME_ROOT="$home_dir" DEV_WORK_ROOT="$work_root" PATH="$test_path" \
    /bin/bash bin/executable_dev-sync pull >/dev/null
[[ -f "$root/chezmoi-applied" ]]

HOME="$home_dir" DEV_HOME_ROOT="$home_dir" DEV_WORK_ROOT="$work_root" PATH="$test_path" \
    /bin/bash bin/executable_dev-sync push >/dev/null

CODEX_LOG="$root/codex.log" HOME="$home_dir" DEV_HOME_ROOT="$home_dir" DEV_WORK_ROOT="$work_root" PATH="$test_path" \
    /bin/bash bin/executable_dev-sync refresh >/dev/null
grep -qx 'plugin marketplace upgrade ponytail' "$root/codex.log"
grep -qx 'plugin remove imoten@imoten-local' "$root/codex.log"
grep -qx 'plugin add naru-codex@naru' "$root/codex.log"

echo "dev-sync behavior passed"
