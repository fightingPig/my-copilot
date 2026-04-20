#!/bin/bash
set -eu

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
FORMAT_JAR="$PROJECT_DIR/.claude/google-java-format.jar"
P3C_JAR="$PROJECT_DIR/.claude/p3c-pmd.jar"
P3C_RULES="$PROJECT_DIR/.claude/p3c-rules.xml"
CHECKSTYLE_JAR="$PROJECT_DIR/.claude/checkstyle.jar"
CHECKSTYLE_RULES="$PROJECT_DIR/.claude/checkstyle.xml"
PROJECT_CONFIG="$PROJECT_DIR/.claude/project-config.json"

HOOK_JSON=$(cat)

CONFIG_RESULT=$(HOOK_JSON="$HOOK_JSON" PROJECT_DIR="$PROJECT_DIR" python3 - <<'PY'
import json
import os
import sys

project_dir = os.environ["PROJECT_DIR"]
config_path = os.path.join(project_dir, ".claude", "project-config.json")
payload = json.loads(os.environ["HOOK_JSON"])
config = {}
if os.path.exists(config_path):
    with open(config_path, "r", encoding="utf-8") as fh:
        config = json.load(fh)

tooling = config.get("tooling", {})
hooks = config.get("hooks", {})
state_dir = os.path.join(project_dir, hooks.get("stateDir", ".claude/state"))

result = {
    "filePath": payload.get("tool_input", {}).get("file_path", ""),
    "enableFormatter": tooling.get("enableFormatter", True),
    "enableP3C": tooling.get("enableP3C", True),
    "enableCheckstyle": tooling.get("enableCheckstyle", True),
    "maxRepairRounds": hooks.get("maxRepairRounds", 3),
    "stateDir": state_dir,
    "shell": os.environ.get("SHELL", "")
}
print(json.dumps(result))
PY
)

FILE_PATH=$(CONFIG_RESULT="$CONFIG_RESULT" python3 - <<'PY'
import json
import os
print(json.loads(os.environ["CONFIG_RESULT"])["filePath"])
PY
)

ENABLE_FORMATTER=$(CONFIG_RESULT="$CONFIG_RESULT" python3 - <<'PY'
import json
import os
print("true" if json.loads(os.environ["CONFIG_RESULT"])["enableFormatter"] else "false")
PY
)

ENABLE_P3C=$(CONFIG_RESULT="$CONFIG_RESULT" python3 - <<'PY'
import json
import os
print("true" if json.loads(os.environ["CONFIG_RESULT"])["enableP3C"] else "false")
PY
)

ENABLE_CHECKSTYLE=$(CONFIG_RESULT="$CONFIG_RESULT" python3 - <<'PY'
import json
import os
print("true" if json.loads(os.environ["CONFIG_RESULT"])["enableCheckstyle"] else "false")
PY
)

MAX_REPAIR_ROUNDS=$(CONFIG_RESULT="$CONFIG_RESULT" python3 - <<'PY'
import json
import os
print(json.loads(os.environ["CONFIG_RESULT"])["maxRepairRounds"])
PY
)

STATE_DIR=$(CONFIG_RESULT="$CONFIG_RESULT" python3 - <<'PY'
import json
import os
print(json.loads(os.environ["CONFIG_RESULT"])["stateDir"])
PY
)

CURRENT_SHELL=$(CONFIG_RESULT="$CONFIG_RESULT" python3 - <<'PY'
import json
import os
print(json.loads(os.environ["CONFIG_RESULT"]).get("shell", ""))
PY
)

mkdir -p "$STATE_DIR"
STATE_FILE="$STATE_DIR/repair-state.json"
if [[ ! -f "$STATE_FILE" ]]; then
  printf '%s\n' '{}' > "$STATE_FILE"
fi

if [[ "$FILE_PATH" != *.java ]] || [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* || "$OSTYPE" == win32* ]]; then
  echo "warning: 推荐在 WSL 或类 Unix shell 中运行当前 Hook 脚本" >&2
fi

if [[ "$ENABLE_FORMATTER" == "true" && -f "$FORMAT_JAR" ]]; then
  java -jar "$FORMAT_JAR" --replace "$FILE_PATH" >/dev/null 2>&1 || true
fi

VIOLATION_FILE="$(mktemp)"
cleanup() {
  rm -f "$VIOLATION_FILE"
}
trap cleanup EXIT

dedupe_file() {
  python3 - "$1" <<'PY'
import collections
import os
import sys

path = sys.argv[1]
if not os.path.exists(path):
    sys.exit(0)

items = []
seen = set()
with open(path, "r", encoding="utf-8") as fh:
    for raw in fh:
        line = raw.strip()
        if not line:
            continue
        key = line
        if key in seen:
            continue
        seen.add(key)
        items.append(line)

with open(path, "w", encoding="utf-8") as fh:
    for item in items:
        fh.write(item + "\n")
PY
}

if [[ "$ENABLE_P3C" == "true" && -f "$P3C_JAR" && -f "$P3C_RULES" ]]; then
  java -cp "$P3C_JAR" net.sourceforge.pmd.PMD -d "$FILE_PATH" -f text -R "$P3C_RULES" 2>/dev/null \
    | python3 -c '
import re
import sys

file_path = sys.argv[1]
for raw in sys.stdin:
    line = raw.strip()
    if not line or "No problems found" in line:
        continue
    m = re.search(r":(\d+):", line)
    line_no = m.group(1) if m else "?"
    parts = line.split(":")
    message = ":".join(parts[3:]).strip() if len(parts) >= 4 else line
    print(f"- 文件：{file_path}，行号：{line_no}，来源：P3C，问题：{message}")
' "$FILE_PATH" >> "$VIOLATION_FILE"
fi

if [[ "$ENABLE_CHECKSTYLE" == "true" && -f "$CHECKSTYLE_JAR" && -f "$CHECKSTYLE_RULES" ]]; then
  java -jar "$CHECKSTYLE_JAR" -c "$CHECKSTYLE_RULES" "$FILE_PATH" 2>/dev/null \
    | python3 -c '
import re
import sys

file_path = sys.argv[1]
for raw in sys.stdin:
    line = raw.strip()
    if not line or "error" not in line.lower():
        continue
    m = re.search(r":(\d+):", line)
    line_no = m.group(1) if m else "?"
    parts = line.split(":")
    message = ":".join(parts[3:]).strip() if len(parts) >= 4 else line
    print(f"- 文件：{file_path}，行号：{line_no}，来源：Checkstyle，问题：{message}")
' "$FILE_PATH" >> "$VIOLATION_FILE"
fi

dedupe_file "$VIOLATION_FILE"

if [[ ! -s "$VIOLATION_FILE" ]]; then
  STATE_FILE="$STATE_FILE" TARGET_FILE="$FILE_PATH" python3 - <<'PY'
import json
import os

state_file = os.environ["STATE_FILE"]
target_file = os.environ["TARGET_FILE"]

with open(state_file, "r", encoding="utf-8") as fh:
    data = json.load(fh)

data.pop(target_file, None)

with open(state_file, "w", encoding="utf-8") as fh:
    json.dump(data, fh, ensure_ascii=False, indent=2)
PY
  exit 0
fi

ROUND_INFO=$(STATE_FILE="$STATE_FILE" TARGET_FILE="$FILE_PATH" MAX_REPAIR_ROUNDS="$MAX_REPAIR_ROUNDS" python3 - <<'PY'
import json
import os
from datetime import datetime, timezone

state_file = os.environ["STATE_FILE"]
target_file = os.environ["TARGET_FILE"]
max_rounds = int(os.environ["MAX_REPAIR_ROUNDS"])

with open(state_file, "r", encoding="utf-8") as fh:
    data = json.load(fh)

entry = data.get(target_file, {"count": 0})
entry["count"] = entry.get("count", 0) + 1
entry["maxRounds"] = max_rounds
entry["lastUpdated"] = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
entry["lastDecision"] = "block"
data[target_file] = entry

with open(state_file, "w", encoding="utf-8") as fh:
    json.dump(data, fh, ensure_ascii=False, indent=2)

print(json.dumps(entry, ensure_ascii=False))
PY
)

REASON=$(python3 - "$VIOLATION_FILE" "$ROUND_INFO" "$STATE_FILE" "$FILE_PATH" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    details = fh.read().strip()

round_info = json.loads(sys.argv[2])
count = round_info["count"]
max_rounds = round_info["maxRounds"]

with open(sys.argv[3], "r", encoding="utf-8") as fh:
    state = json.load(fh)

entry = state.get(sys.argv[4], {})
entry["lastViolations"] = details.splitlines()
state[sys.argv[4]] = entry

with open(sys.argv[3], "w", encoding="utf-8") as fh:
    json.dump(state, fh, ensure_ascii=False, indent=2)

if count >= max_rounds:
    message = (
        f"Java 规范校验仍未通过，当前文件已达到最大自动修复轮次 {count}/{max_rounds}。"
        "请停止继续自动扩大修复范围，向用户明确说明需要人工接管，并附上当前违规清单：\n"
        + details
    )
else:
    message = (
        f"Java 规范校验未通过，当前为自动修复第 {count}/{max_rounds} 轮。"
        "请仅针对以下违规项做最小化修复，不要改动无关业务逻辑：\n"
        + details
    )
print(json.dumps(message, ensure_ascii=False))
PY
)

printf '%s\n' "{"
printf '%s\n' '  "hookSpecificOutput": {'
printf '%s\n' '    "hookEventName": "PostToolUse",'
printf '%s\n' '    "decision": "block",'
printf '    "reason": %s\n' "$REASON"
printf '%s\n' '  }'
printf '%s\n' "}"
