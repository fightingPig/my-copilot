#!/bin/bash
set -eu

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
TMP_DIR="$PROJECT_DIR/tmp/verify"
mkdir -p "$TMP_DIR"

echo "[1/8] settings.json"
python3 -m json.tool "$PROJECT_DIR/.claude/settings.json" >/dev/null

echo "[2/8] project-config.json"
python3 -m json.tool "$PROJECT_DIR/.claude/project-config.json" >/dev/null

echo "[3/8] render standards"
"$PROJECT_DIR/.claude/tools/render-standards.sh" >/dev/null

echo "[4/8] hook shell syntax"
bash -n "$PROJECT_DIR/.claude/hooks/session-init.sh"
bash -n "$PROJECT_DIR/.claude/hooks/java-pre-check.sh"
bash -n "$PROJECT_DIR/.claude/hooks/java-post-check.sh"
bash -n "$PROJECT_DIR/.claude/hooks/pre-compact.sh"
bash -n "$PROJECT_DIR/.claude/tools/add-rule-case.sh"
bash -n "$PROJECT_DIR/.claude/tools/render-standards.sh"

echo "[5/8] xml"
python3 - <<'PY'
import xml.etree.ElementTree as ET
ET.parse('.claude/checkstyle.xml')
ET.parse('.claude/checkstyle-strict.xml')
ET.parse('.claude/p3c-rules.xml')
print('xml ok')
PY

echo "[6/8] pre-check"
printf '%s' '{"tool_input":{"file_path":"'"$PROJECT_DIR"'/tmp/verify/HighRisk.java","content":"public class HighRisk { void run(){ System.out.println(1); } }"}}' \
  | "$PROJECT_DIR/.claude/hooks/java-pre-check.sh" >/dev/null

echo "[7/8] formatter"
printf '%s\n' 'public class FormatMe{public void run(){int a=1;System.out.println(a);}}' > "$TMP_DIR/FormatMe.java"
java -jar "$PROJECT_DIR/.claude/google-java-format.jar" --replace "$TMP_DIR/FormatMe.java"

echo "[8/8] post-check"
printf '%s\n' 'public class FormatMe{public void run(){int a=1;System.out.println(a);}}' > "$TMP_DIR/FormatMeHook.java"
printf '%s' '{"tool_input":{"file_path":"'"$PROJECT_DIR"'/tmp/verify/FormatMeHook.java"}}' \
  | "$PROJECT_DIR/.claude/hooks/java-post-check.sh" >/dev/null
java -jar "$PROJECT_DIR/.claude/checkstyle.jar" -c "$PROJECT_DIR/.claude/checkstyle.xml" "$TMP_DIR/FormatMeHook.java" >/dev/null

echo "verify ok"
