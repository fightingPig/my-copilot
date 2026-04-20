#!/bin/bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_CONFIG="$CLAUDE_DIR/project-config.json"

cd "$CLAUDE_DIR"

P3C_URL="${P3C_URL:-}"
CHECKSTYLE_URL="${CHECKSTYLE_URL:-}"
GOOGLE_JAVA_FORMAT_URL="${GOOGLE_JAVA_FORMAT_URL:-}"

if [[ -f "$PROJECT_CONFIG" ]]; then
  eval "$(PROJECT_CONFIG_PATH="$PROJECT_CONFIG" python3 - <<'PY'
import json
import os

with open(os.environ["PROJECT_CONFIG_PATH"], "r", encoding="utf-8") as fh:
    config = json.load(fh)

download = config.get("download", {})
print(f'DEFAULT_P3C_URL="{download.get("p3cUrl", "")}"')
print(f'DEFAULT_CHECKSTYLE_URL="{download.get("checkstyleUrl", "")}"')
print(f'DEFAULT_GOOGLE_JAVA_FORMAT_URL="{download.get("googleJavaFormatUrl", "")}"')
PY
)"
fi

P3C_URL="${P3C_URL:-$DEFAULT_P3C_URL}"
CHECKSTYLE_URL="${CHECKSTYLE_URL:-$DEFAULT_CHECKSTYLE_URL}"
GOOGLE_JAVA_FORMAT_URL="${GOOGLE_JAVA_FORMAT_URL:-$DEFAULT_GOOGLE_JAVA_FORMAT_URL}"

curl -fL "$P3C_URL" -o p3c-pmd.jar
curl -fL "$CHECKSTYLE_URL" -o checkstyle.jar
curl -fL "$GOOGLE_JAVA_FORMAT_URL" -o google-java-format.jar

echo "Jar 下载完成：$CLAUDE_DIR"
