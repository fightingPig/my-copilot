# Guardrail Checklist

## 0. 准备

- [ ] 在项目根目录执行 `chmod +x .claude/hooks/*.sh .claude/tools/*.sh`
- [ ] 修改 [`.claude/project-config.json`](/Users/zs/my-project/未命名文件夹/.claude/project-config.json) 中的项目名、根包名和 JDK
- [ ] 执行 [`.claude/tools/render-standards.sh`](/Users/zs/my-project/未命名文件夹/.claude/tools/render-standards.sh)
- [ ] 执行 [`.claude/tools/verify-guardrail.sh`](/Users/zs/my-project/未命名文件夹/.claude/tools/verify-guardrail.sh)，看到 `verify ok`

## 1. Hook 注册

- [ ] 在 Claude Code 中执行 `/hooks`
- [ ] 确认存在 `SessionStart`
- [ ] 确认存在 `PreToolUse`
- [ ] 确认存在 `PostToolUse`
- [ ] 确认存在 `PreCompact`

## 2. 会话初始化

- [ ] 执行 `.claude/hooks/session-init.sh`
- [ ] 确认输出项目配置摘要
- [ ] 确认输出编码规范摘要
- [ ] 确认输出高危规则摘要

## 3. 规则手册

- [ ] 打开 [`.claude/rule.md`](/Users/zs/my-project/未命名文件夹/.claude/rule.md)
- [ ] 确认存在 `HR-001` 到 `HR-004`
- [ ] 执行 `.claude/tools/add-rule-case.sh HR-900 "测试规则" 待观察 人工确认`
- [ ] 确认规则模板被追加
- [ ] 删除测试规则或回滚该追加

## 4. 写前高危拦截

- [ ] 用 `System.out.println` 触发 `HR-001`
- [ ] 用 `Executors.newFixedThreadPool` 触发 `HR-002`
- [ ] 用硬编码密钥触发 `HR-003`
- [ ] 用 SQL 拼接触发 `HR-004`
- [ ] 确认返回 JSON 中带规则编号和行号

## 5. 规则级开关

- [ ] 在 [`.claude/project-config.json`](/Users/zs/my-project/未命名文件夹/.claude/project-config.json) 中临时把某条规则的 `enabled` 改成 `false`
- [ ] 重新触发对应场景
- [ ] 确认该规则不再拦截
- [ ] 恢复配置

## 6. 自动格式化

- [ ] 准备一份一行乱格式 Java 文件
- [ ] 执行 `PostToolUse` Hook
- [ ] 确认文件被自动格式化

## 7. 写后规范反馈

- [ ] 用 `catch (Exception)` 触发 Checkstyle
- [ ] 确认返回 `block`
- [ ] 确认 `reason` 中带文件、行号、来源、问题

## 8. 违规归并

- [ ] 准备一份同时触发多个重复格式问题的文件
- [ ] 执行 `PostToolUse`
- [ ] 确认返回结果没有大量完全重复的条目

## 9. 修复轮次状态

- [ ] 连续 3 次让同一文件触发同一问题
- [ ] 确认第 1 次提示 `1/3`
- [ ] 确认第 2 次提示 `2/3`
- [ ] 确认第 3 次提示需要人工接管
- [ ] 打开 [`.claude/state/repair-state.json`](/Users/zs/my-project/未命名文件夹/.claude/state/repair-state.json)
- [ ] 确认记录了 `count`、`maxRounds`、`lastUpdated`、`lastDecision`

## 10. 修复成功后清理状态

- [ ] 把前一步的违规文件修正
- [ ] 再执行一次 `PostToolUse`
- [ ] 确认状态文件中对应条目被清理

## 11. 默认与严格 Checkstyle

- [ ] 用默认版执行 `java -jar .claude/checkstyle.jar -c .claude/checkstyle.xml <file>`
- [ ] 用严格版执行 `java -jar .claude/checkstyle.jar -c .claude/checkstyle-strict.xml <file>`
- [ ] 确认严格版报错不少于默认版

## 12. P3C

- [ ] 执行 `java -cp .claude/p3c-pmd.jar net.sourceforge.pmd.PMD -d <file> -f text -R .claude/p3c-rules.xml`
- [ ] 确认命令能正常运行

## 13. 通过样例

- [ ] 检查 [`samples/passing`](/Users/zs/my-project/未命名文件夹/samples/passing) 目录
- [ ] 用默认 Checkstyle 检查通过样例
- [ ] 用 `PostToolUse` 检查通过样例
- [ ] 确认没有误伤

## 14. 违规样例

- [ ] 运行 [`samples/violations`](/Users/zs/my-project/未命名文件夹/samples/violations) 中的每个样例
- [ ] 确认能触发对应预期

## 15. 下载脚本

- [ ] 执行 `.claude/tools/download-jars.sh`
- [ ] 确认 3 个 Jar 存在
- [ ] 临时用环境变量覆盖下载地址
- [ ] 用 `bash -x .claude/tools/download-jars.sh` 确认脚本优先读取覆盖值

## 16. 规范文档渲染

- [ ] 修改 `project-config.json` 中的 `jdkVersion`
- [ ] 执行 `.claude/tools/render-standards.sh`
- [ ] 确认 [`.claude/java-coding-standards.md`](/Users/zs/my-project/未命名文件夹/.claude/java-coding-standards.md) 头部同步变化
- [ ] 还原配置

## 17. ArchUnit 测试骨架

- [ ] 打开 [ArchitectureRuleTest.java](/Users/zs/my-project/未命名文件夹/src/test/java/com/example/demo/ArchitectureRuleTest.java)
- [ ] 替换 `ROOT_PACKAGE`
- [ ] 确认包含 Controller 不得直接依赖 DAO
- [ ] 确认包含 Service 不得依赖 Controller

## 18. 文档与交付

- [ ] 阅读 [Java 项目 AI 编码规范自动修复闭环配置方案.md](/Users/zs/my-project/未命名文件夹/Java%20项目%20AI%20编码规范自动修复闭环配置方案.md)
- [ ] 阅读 [DELIVERY.md](/Users/zs/my-project/未命名文件夹/DELIVERY.md)
- [ ] 阅读 [`.claude/rule-governance.md`](/Users/zs/my-project/未命名文件夹/.claude/rule-governance.md)

## 19. Windows / WSL

- [ ] 若在 Windows，确认优先使用 WSL
- [ ] 若不在 WSL，确认脚本会给出提示

## 20. 端到端

- [ ] 在 Claude Code 中让 AI 生成使用 `Executors` 和 `System.out.println` 的代码
- [ ] 确认第一次被 `PreToolUse` 拦截
- [ ] 确认 AI 重新生成安全实现
- [ ] 确认写后仍会走格式化和校验
