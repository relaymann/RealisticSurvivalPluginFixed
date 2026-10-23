#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_TOKEN:?GitHub Actions token is required to publish the compatibility JAR}"
: "${GITHUB_REPOSITORY:?GitHub repository context is required}"
: "${GITHUB_SHA:?Source commit SHA is required}"
: "${GITHUB_RUN_ID:?GitHub Actions run ID is required}"

shopt -s nullglob
jars=(target/realisticsurvival-*-mc26.jar)
if [[ ${#jars[@]} -ne 1 || ! -s "${jars[0]:-}" ]]; then
  echo "Expected exactly one non-empty target/realisticsurvival-*-mc26.jar." >&2
  exit 1
fi

source_jar="${jars[0]}"
artifact_name="RealisticSurvival-1.2.9-RELEASE-Paper-26.1.2.jar"
publish_dir="${RUNNER_TEMP:-/tmp}/realisticsurvival-publish-${GITHUB_RUN_ID}"
rm -rf "$publish_dir"
mkdir -p "$publish_dir"

cp "$source_jar" "$publish_dir/$artifact_name"
(
  cd "$publish_dir"
  sha256sum "$artifact_name" > SHA256SUMS.txt
)

cat > "$publish_dir/BUILD_INFO.txt" <<EOF
Product: RealisticSurvival 1.2.9-RELEASE
Target: Paper 26.1.2 / Minecraft 26.1.2
Source repository: https://github.com/${GITHUB_REPOSITORY}
Source commit: ${GITHUB_SHA}
Workflow run: ${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}
Build time UTC: $(date -u +'%Y-%m-%dT%H:%M:%SZ')

This file records build provenance only. A successful compile and JAR-content
check are not a substitute for in-game testing on a staging Paper 26.1.2 server.
EOF

cat > "$publish_dir/README.md" <<'EOF'
# RealisticSurvival — Paper 26.1.2 build

This branch contains the latest JAR published by the repository's MC 26.1.2
build workflow, together with build metadata and a SHA-256 checksum.

Use this JAR only on a backed-up staging server first. Keep exactly one
RealisticSurvival JAR in the server's plugins directory.
EOF

git -C "$publish_dir" init --quiet --initial-branch=mc26-builds
git -C "$publish_dir" config user.name "github-actions[bot]"
git -C "$publish_dir" config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git -C "$publish_dir" add "$artifact_name" SHA256SUMS.txt BUILD_INFO.txt README.md
git -C "$publish_dir" commit --quiet -m "Publish Paper 26.1.2 compatibility JAR from ${GITHUB_SHA:0:12}"

remote="https://github.com/${GITHUB_REPOSITORY}.git"
auth_header="AUTHORIZATION: basic $(printf 'x-access-token:%s' "$GITHUB_TOKEN" | base64 | tr -d '\n')"

git -C "$publish_dir" -c http.extraheader="$auth_header" push --force "$remote" HEAD:refs/heads/mc26-builds

echo "Published the compatibility JAR to branch mc26-builds."
echo "Direct download: ${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/raw/refs/heads/mc26-builds/$artifact_name"
cat "$publish_dir/SHA256SUMS.txt"
