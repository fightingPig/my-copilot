# Delivery Guide

## 最短使用步骤

1. 修改 [`.claude/project-config.json`](/Users/zs/my-project/未命名文件夹/.claude/project-config.json) 中的项目名、根包名、JDK 和镜像地址。
2. 执行：

```bash
chmod +x .claude/hooks/*.sh .claude/tools/*.sh
.claude/tools/render-standards.sh
.claude/tools/download-jars.sh
.claude/tools/verify-guardrail.sh
```

3. 在 Claude Code 中执行：

```text
/hooks
```

确认 Hook 已注册。

## 最短验收

1. 高危拦截：
   用 `Executors` + `System.out.println` 触发 `PreToolUse deny`。
2. 格式化：
   用一行乱格式 Java 代码触发 `PostToolUse`，确认文件被自动格式化。
3. 写后反馈：
   用 `catch (Exception)` 触发 `PostToolUse block`。
4. 修复轮次：
   连续 3 次让同一个文件校验失败，确认第三次进入人工接管提示。

## 交付建议

1. 若目标环境无公网，提前把 3 个 Jar 连同模板一起打包。
2. 若团队刚开始试点，默认使用保守版 `checkstyle.xml`。
3. 若团队准备收紧规范，再切到 `checkstyle-strict.xml`。
