#!/bin/bash
set -eu

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
STANDARD_FILE="$PROJECT_DIR/.claude/java-coding-standards.md"

if [ -f "$STANDARD_FILE" ]; then
  echo "[压缩提示] 请保留当前项目的 Java 编码规范、未修复违规项和最小化修复原则。"
fi
