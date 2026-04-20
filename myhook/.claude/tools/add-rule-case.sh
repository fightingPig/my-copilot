#!/bin/bash
set -eu

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
RULE_FILE="$PROJECT_DIR/.claude/rule.md"

RULE_ID="${1:-}"
TITLE="${2:-}"
TYPE="${3:-待观察}"
ACTION="${4:-人工确认}"

if [[ -z "$RULE_ID" || -z "$TITLE" ]]; then
  echo "usage: .claude/tools/add-rule-case.sh HR-005 \"规则标题\" [类型] [默认动作]"
  exit 1
fi

cat >> "$RULE_FILE" <<EOF

## ${RULE_ID} ${TITLE}

- 类型：${TYPE}
- 默认动作：${ACTION}
- 风险说明：
  待补充。
- 推荐替代：
  待补充。
- 真实案例：
  待补充。
- 规则决策：
  待补充。
EOF

echo "已追加规则模板到 $RULE_FILE"
