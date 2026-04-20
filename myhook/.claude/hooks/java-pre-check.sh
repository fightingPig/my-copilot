#!/bin/bash
set -eu

HOOK_JSON=$(cat)

HOOK_JSON="$HOOK_JSON" python3 - <<'PY'
import json
import os
import re
import sys

payload = json.loads(os.environ["HOOK_JSON"])
tool_input = payload.get("tool_input", {})
file_path = tool_input.get("file_path", "")
content = tool_input.get("content", "")
project_dir = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
config_path = os.path.join(project_dir, ".claude", "project-config.json")

if not file_path.endswith(".java"):
    sys.exit(0)

config = {}
if os.path.exists(config_path):
    with open(config_path, "r", encoding="utf-8") as fh:
        config = json.load(fh)

precheck_config = config.get("precheck", {})
rule_config = config.get("rules", {})

violations = []

checks = [
    (precheck_config.get("denySystemOut", True), "HR-001", r"System\.(out|err)\.println\s*\(", "禁止使用 System.out/System.err 打印日志"),
    (precheck_config.get("denyExecutorsFactory", True), "HR-002", r"Executors\.new(FixedThreadPool|CachedThreadPool|SingleThreadExecutor|ScheduledThreadPool)\s*\(", "禁止使用 Executors 快捷工厂创建线程池"),
    (precheck_config.get("denyHardcodedSecrets", True), "HR-003", r'(?i)(password|passwd|secret|token|access[_-]?key|secret[_-]?key)\s*=\s*"[^"]+"', "疑似硬编码敏感信息"),
    (precheck_config.get("denySqlStringConcat", True), "HR-004", r'(?i)(select|update|delete|insert).*(\"\\s*\\+\\s*[a-zA-Z_])', "疑似 SQL 字符串拼接，请确认是否未参数化")
]

for enabled, rule_id, pattern, message in checks:
    if not enabled:
        continue
    rule_entry = rule_config.get(rule_id, {})
    if not rule_entry.get("enabled", True):
        continue
    if rule_entry.get("action", "deny") != "deny":
        continue
    for match in re.finditer(pattern, content, re.DOTALL):
        line_no = content.count("\n", 0, match.start()) + 1
        violations.append(f"{rule_id} 行 {line_no}: {message}")
        break

if not violations:
    sys.exit(0)

result = {
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": "Java 写入前风险预检未通过：" + "；".join(violations) + "。详见 .claude/rule.md"
    }
}

json.dump(result, sys.stdout, ensure_ascii=False)
PY
