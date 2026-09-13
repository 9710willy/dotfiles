#!/bin/bash

set -euo pipefail

root=$(mktemp -d "${TMPDIR:-/tmp}/deepseek-catalog-test.XXXXXX")
trap 'rm -rf "$root"' EXIT

mkdir -p "$root/bin" "$root/home"

cat > "$root/bin/curl" <<'EOF'
#!/bin/bash
output=''
while [[ $# -gt 0 ]]; do
    if [[ "$1" == "-o" ]]; then
        output="$2"
        shift 2
    else
        shift
    fi
done
cat > "$output" <<'SCRIPT'
write_models_json() {
  cat > "$1" <<'CODEX_MODELS_JSON'
{
  "models": [
    {"slug": "deepseek-flash"},
    {"slug": "deepseek-v4-pro"}
  ]
}
CODEX_MODELS_JSON
}
SCRIPT
EOF
chmod +x "$root/bin/curl"

HOME="$root/home" PATH="$root/bin:/usr/bin:/bin" \
    /bin/bash bin/executable_update-deepseek-catalog >/dev/null

jq -e '
    [.models[].slug] | sort == ["deepseek-flash", "deepseek-v4-pro"]
' "$root/home/.codex/models.json" >/dev/null
[[ "$(stat -f %Lp "$root/home/.codex/models.json")" == "600" ]]

echo "DeepSeek catalog update passed"
