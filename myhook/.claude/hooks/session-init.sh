#!/bin/bash
set -eu

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
STANDARD_FILE="$PROJECT_DIR/.claude/java-coding-standards.md"
POM_FILE="$PROJECT_DIR/pom.xml"
PROJECT_CONFIG="$PROJECT_DIR/.claude/project-config.json"
RULE_FILE="$PROJECT_DIR/.claude/rule.md"

echo "=== Java AI Coding Session Init ==="

if [ -f "$PROJECT_CONFIG" ]; then
  echo
  echo "[项目配置摘要]"
  PROJECT_CONFIG_PATH="$PROJECT_CONFIG" python3 - <<'PY'
import json
import os

with open(os.environ["PROJECT_CONFIG_PATH"], "r", encoding="utf-8") as fh:
    config = json.load(fh)

project = config.get("project", {})
hooks = config.get("hooks", {})
tooling = config.get("tooling", {})

print(f"项目名: {project.get('name', '-')}")
print(f"根包名: {project.get('rootPackage', '-')}")
print(f"JDK: {project.get('jdkVersion', '-')}")
print(f"架构: {project.get('architecture', '-')}")
print(f"最大自动修复轮次: {hooks.get('maxRepairRounds', '-')}")
print(f"Formatter/P3C/Checkstyle: {tooling.get('enableFormatter')} / {tooling.get('enableP3C')} / {tooling.get('enableCheckstyle')}")
PY
fi

if [ -f "$STANDARD_FILE" ]; then
  echo
  echo "[项目编码规范摘要]"
  sed -n '1,200p' "$STANDARD_FILE"
fi

if [ -f "$RULE_FILE" ]; then
  echo
  echo "[高危与敏感规则摘要]"
  sed -n '1,120p' "$RULE_FILE"
fi

if [ -f "$POM_FILE" ]; then
  echo
  echo "[项目基础信息]"
  grep -E "<groupId>|<artifactId>|<version>|<java.version>|<spring-boot.version>" "$POM_FILE" | head -20 || true
fi

echo
echo "[修复原则]"
echo "1. 优先最小修复，只改违规点。"
echo "2. 不改动无关业务逻辑。"
echo "3. 写入前高风险规则会被阻断，写入后普通规范问题会继续自动修复。"
