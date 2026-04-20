# code_copilot 框架

> 渐进式 AI 编码协作框架

## 概述

code_copilot 是一个基于 Spec 驱动的 AI 编码协作框架，通过结构化文档（Spec）明确"要做什么、怎么做、有什么约束"，然后 AI 围绕这份文档编码。

## 核心铁律

1. **No Spec, No Code** — 没有文档，不准写代码
2. **Spec is Truth** — 文档和代码冲突时，错的一定是代码
3. **Reverse Sync** — 发现 Bug，先修文档，再修代码

## 目录结构

```
code_copilot/
├── README.md                           # 框架说明
├── agents/                             # Agent 配置与提示词
│   ├── copilot-prompt.md               # 主 Agent 完整提示词（核心）
│   ├── spec-reviewer.md                # Spec 合规审查 Agent
│   └── code-quality-reviewer.md         # 代码质量审查 Agent
├── rules/                              # 项目约束（始终生效）
│   ├── project-context.md              # 工程结构与依赖（/init 填充）
│   ├── coding-style.md                 # 编码规范
│   ├── security.md                     # 安全红线
│   └── domain-rules.md                 # 业务领域约束
├── knowledge/                          # 领域知识（按需加载）
│   └── index.md                        # 知识索引
└── changes/                            # 变更管理
    └── templates/                      # 模板目录
        ├── spec.md                     # Spec 模板
        ├── tasks.md                    # Tasks 模板
        ├── test-spec.md                # 单测 Spec 模板
        └── log.md                      # Log 模板
```

## 工作流

- `/propose` — 提案阶段：Research → 提问收敛 → 生成 Spec + Tasks
- `/apply` — 执行阶段：按 Tasks 逐个执行，人工审查
- `/fix` — 修正阶段：Review 后的增量修正
- `/review` — 审查阶段：Spec 合规 → 代码质量两阶段审查
- `/archive` — 归档阶段：知识沉淀到 knowledge/

## 使用前提

项目特定内容（应用名、包名、中间件等）需根据实际情况填充 `rules/project-context.md`。
