# Java 项目 AI 编码规范自动修复闭环配置方案

## 方案目标

本文提供一套可直接落地到 Claude Code 项目的 Java 规范闭环方案，覆盖以下目标：

1. 会话启动时向 AI 注入项目编码规范与项目参数。
2. 写入 Java 文件前，对高风险内容做快速预检查并阻断。
3. 写入 Java 文件后，先格式化，再执行 P3C + Checkstyle 校验。
4. 将违规清单结构化反馈给 Claude，驱动其继续最小化修复。
5. 对自动修复轮次做状态控制，避免陷入无限修复循环。

这版方案已经把上一版中容易踩坑的地方全部收口，并落实了以下 10 项优化：

1. 参数化项目配置，而不是把 JDK、根包名、工具开关写死在文档里。
2. 增加自动修复轮次状态控制。
3. 明确区分写前高危阻断和写后普通规范反馈。
4. 写前预检反馈增加命中行号。
5. 补齐最小可运行样例。
6. 支持离线 / 内网镜像下载方案。
7. 默认 Checkstyle 改为保守基线，并提供严格版。
8. 明确 Windows 使用建议。
9. 增加 Hook 调试与排障脚本。
10. 强化示例架构测试约束。

---

## 一、前置环境要求

1. JDK 8+。
2. Claude Code 桌面版。
3. Bash 环境。
4. Python 3。
5. 无需全局安装 `checkstyle`、`pmd`，全部通过项目内 Jar 包运行。

当前模板的运行兼容性：

1. `p3c-pmd 2.1.1` 可运行在 JDK 8+。
2. `checkstyle 8.45.1` 可运行在 JDK 8+。
3. `google-java-format 1.7` 可运行在 JDK 8+。

说明：

1. 如果你未来升级 `checkstyle` 或 `google-java-format`，必须重新核对最低运行 JDK。
2. 当前模板默认按 Java 8 兼容基线生成，适合老项目和保守交付环境。

---

## 二、目录结构

```text
your-java-project/
├── .copilot-instructions.md
├── .gitignore
├── pom.xml
├── .claude/
│   ├── settings.json
│   ├── project-config.json
│   ├── rule.md
│   ├── java-coding-standards.md
│   ├── p3c-rules.xml
│   ├── checkstyle.xml
│   ├── checkstyle-strict.xml
│   ├── rule-governance.md
│   ├── hooks/
│   │   ├── session-init.sh
│   │   ├── java-pre-check.sh
│   │   ├── java-post-check.sh
│   │   └── pre-compact.sh
│   ├── tools/
│   │   ├── render-standards.sh
│   │   ├── download-jars.sh
│   │   ├── add-rule-case.sh
│   │   └── verify-guardrail.sh
│   ├── state/
│   │   └── repair-state.json
│   ├── p3c-pmd.jar
│   ├── checkstyle.jar
│   └── google-java-format.jar
├── samples/
│   ├── passing/
│   │   ├── CompliantService.java
│   │   └── NamedThreadPoolFactory.java
│   └── violations/
│       ├── HighRiskExecutors.java
│       ├── FormattingAndCatch.java
│       └── SensitiveConfig.java
├── src/test/java/com/example/demo/
│   └── ArchitectureRuleTest.java
├── DELIVERY.md
└── CHECKLIST.md
```

说明：

1. `.claude/project-config.json` 是项目参数中心。
2. `.claude/rule.md` 是高危与敏感规则沉淀手册。
3. `.claude/state/repair-state.json` 用于记录每个文件的自动修复轮次。
4. `.claude/checkstyle.xml` 是默认保守版规则。
5. `.claude/checkstyle-strict.xml` 是可选严格版。
6. `samples/violations/` 用于最小验证与演示。
7. `samples/passing/` 用于验证不会误伤正常代码。
8. `DELIVERY.md` 是最短交付说明。
9. `CHECKLIST.md` 是完整验收清单。

---

## 三、参数化配置设计

### 1. `.claude/project-config.json`

这个文件是本方案的核心增强点之一。当前模板已支持以下参数：

1. `project.name`
2. `project.rootPackage`
3. `project.jdkVersion`
4. `project.framework`
5. `project.frameworkVersion`
6. `project.persistenceFramework`
7. `project.architecture`
8. `hooks.maxRepairRounds`
9. `hooks.stateDir`
10. `tooling.enableFormatter`
11. `tooling.enableP3C`
12. `tooling.enableCheckstyle`
13. `precheck.*`
14. `rules.*`
15. `download.*`

当前示例：

```json
{
  "project": {
    "name": "java-ai-guardrail-template",
    "rootPackage": "com.example.demo",
    "jdkVersion": "8"
  },
  "hooks": {
    "maxRepairRounds": 3,
    "stateDir": ".claude/state"
  },
  "tooling": {
    "enableFormatter": true,
    "enableP3C": true,
    "enableCheckstyle": true
  }
}
```

收益：

1. 后续迁移到别的 Java 项目时，只改一个配置文件即可。
2. 是否启用格式化 / P3C / Checkstyle 不再需要改脚本。
3. 内网镜像下载地址也可以统一放在这个文件里。
4. 规则可以按编号直接控制 `enabled` 和 `action`。

规则级开关示例：

```json
{
  "rules": {
    "HR-001": { "enabled": true, "action": "deny" },
    "HR-002": { "enabled": true, "action": "deny" }
  }
}
```

说明：

1. `enabled=false` 表示完全关闭该条规则。
2. 当前 `PreToolUse` 仅对 `action=deny` 的规则生效。
3. 这让你不改脚本也能直接调整某条规则的处理策略。

---

## 四、规则手册沉淀机制

新增文件： [`.claude/rule.md`](/Users/zs/my-project/未命名文件夹/.claude/rule.md)

用途：

1. 专门沉淀“写前必须拦截”的高危与敏感规则。
2. 为每条规则分配稳定编号，例如 `HR-001`。
3. 让 `PreToolUse` 的拦截反馈直接带规则编号。
4. 支持后续人工介入时快速判断：继续拦截、降级为写后反馈，还是补充边界说明。

当前内置编号：

1. `HR-001` 禁止使用 `System.out/System.err`
2. `HR-002` 禁止使用 `Executors` 快捷工厂
3. `HR-003` 禁止硬编码密码、Token、AK/SK、密钥
4. `HR-004` 禁止明显未参数化的 SQL 字符串拼接

规则沉淀建议：

1. 每新增一条高危规则，必须写明“为什么危险”“推荐替代方案”“真实案例”“当前决策”。
2. 如果某条规则误报率高，不要直接删，先在 `rule.md` 补边界说明。
3. 如果长期确认不适合写前拦截，再降级为写后反馈规则。

追加规则模板工具：

[`add-rule-case.sh`](/Users/zs/my-project/未命名文件夹/.claude/tools/add-rule-case.sh)

示例：

```bash
.claude/tools/add-rule-case.sh HR-005 "禁止手写不带超时的 HTTP 调用" 高危红线 写前拦截
```

规则治理说明文件：

[`rule-governance.md`](/Users/zs/my-project/未命名文件夹/.claude/rule-governance.md)

建议所有新增或调整高危规则前，先按照治理文档做一次评审。

---

## 五、Hook 闭环设计

### 1. Hook 配置

入口文件： [`.claude/settings.json`](/Users/zs/my-project/未命名文件夹/.claude/settings.json)

当前链路：

```text
SessionStart
  -> session-init.sh 注入项目配置摘要和编码规范

PreToolUse(Write|Edit|MultiEdit)
  -> java-pre-check.sh
  -> 高危内容命中则 deny

PostToolUse(Write|Edit|MultiEdit)
  -> java-post-check.sh
  -> 自动格式化
  -> P3C
  -> Checkstyle
  -> 记录修复轮次
  -> 有违规则结构化反馈给 Claude

PreCompact
  -> pre-compact.sh
  -> 保留规范和未修复上下文
```

### 2. 为什么要区分写前与写后

这是第二个关键优化点。

写前阻断只做高危、低歧义内容：

1. `System.out.println`
2. `Executors.newFixedThreadPool` 等快捷工厂
3. 明文密钥、口令、Token
4. 明显的 SQL 字符串拼接

写后反馈才做常规规范问题：

1. 命名
2. 缩进
3. 大括号
4. `IllegalCatch`
5. P3C 常见并发 / OOP / 命名规则

这样做的好处：

1. 写前不会误杀太多正常开发场景。
2. 写后校验更适合承载“AI 继续自动修复”。

---

## 六、自动修复轮次状态控制

这部分由 [`.claude/hooks/java-post-check.sh`](/Users/zs/my-project/未命名文件夹/.claude/hooks/java-post-check.sh) 和 `.claude/state/repair-state.json` 配合实现。

规则：

1. 每个 Java 文件单独计数。
2. 默认最大轮次取 `project-config.json` 中的 `hooks.maxRepairRounds = 3`。
3. 如果校验通过，则清理该文件的状态。
4. 如果连续未通过，则轮次加 1。
5. 达到上限后，反馈内容会明确要求 Claude 停止继续扩大修复范围，并向用户说明需要人工接管。

这能避免：

1. Claude 因为边界条件反复改同一个文件。
2. Hook 永远 block 导致反复循环。

---

## 七、写前预检增强

写前脚本： [`.claude/hooks/java-pre-check.sh`](/Users/zs/my-project/未命名文件夹/.claude/hooks/java-pre-check.sh)

当前增强点：

1. 读取 `.claude/project-config.json` 的开关项。
2. 为命中的高危内容计算行号。
3. 为每条高危规则附加规则编号。
4. 返回 `PreToolUse deny` JSON，并指向 `.claude/rule.md`。

示例反馈风格：

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Java 写入前风险预检未通过：HR-001 行 3: 禁止使用 System.out/System.err 打印日志。详见 .claude/rule.md"
  }
}
```

这比“只告诉你错了”更有用，因为 Claude 可以直接按行修。

---

## 八、写后校验增强

写后脚本： [`.claude/hooks/java-post-check.sh`](/Users/zs/my-project/未命名文件夹/.claude/hooks/java-post-check.sh)

当前策略：

1. 判断目标是否为 Java 文件。
2. 按配置决定是否启用 formatter / P3C / Checkstyle。
3. 先执行 `google-java-format 1.7`。
4. 再执行 P3C。
5. 再执行 Checkstyle。
6. 汇总为“文件 + 行号 + 来源 + 问题”的结构化列表。
7. 对完全重复的违规项做去重。
8. 结合修复轮次状态，返回 JSON。

若未通过，输出类似：

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "decision": "block",
    "reason": "Java 规范校验未通过，当前为自动修复第 1/3 轮。请仅针对以下违规项做最小化修复..."
  }
}
```

注意：

1. `PostToolUse` 的 `block` 不会撤销已经写入的文件。
2. 这里的作用是把违规清单交回 Claude，继续自动修复。
3. 状态文件会额外记录 `lastUpdated`、`lastDecision`、`lastViolations`，便于排障。

---

## 九、Checkstyle 保守版与严格版

这是第七项优化。

### 1. 默认保守版

文件： [`.claude/checkstyle.xml`](/Users/zs/my-project/未命名文件夹/.claude/checkstyle.xml)

默认只保留低争议、对 AI 约束价值高的规则：

1. import 规范
2. 行长
3. 命名
4. 缩进
5. 空格
6. 大括号
7. `IllegalCatch`
8. `FallThrough`

默认移除了噪声更大的：

1. `MethodLength`
2. `ParameterNumber`

### 2. 可选严格版

文件： [`.claude/checkstyle-strict.xml`](/Users/zs/my-project/未命名文件夹/.claude/checkstyle-strict.xml)

如果你的团队想加严，可以切到这个版本，它重新启用了：

1. `MethodLength`
2. `ParameterNumber`

建议：

1. 第一阶段先用保守版，把闭环跑顺。
2. 团队稳定后，再切换或合并严格规则。

---

## 十、样例与验证材料

这是第五项优化。

样例目录： [`samples/violations`](/Users/zs/my-project/未命名文件夹/samples/violations)

包含：

1. [HighRiskExecutors.java](/Users/zs/my-project/未命名文件夹/samples/violations/HighRiskExecutors.java)
   用于验证 `PreToolUse` 高危拦截。
2. [FormattingAndCatch.java](/Users/zs/my-project/未命名文件夹/samples/violations/FormattingAndCatch.java)
   用于验证格式化 + Checkstyle 反馈。
3. [SensitiveConfig.java](/Users/zs/my-project/未命名文件夹/samples/violations/SensitiveConfig.java)
   用于验证硬编码敏感信息预检。

通过样例目录： [`samples/passing`](/Users/zs/my-project/未命名文件夹/samples/passing)

包含：

1. [CompliantService.java](/Users/zs/my-project/未命名文件夹/samples/passing/CompliantService.java)
2. [NamedThreadPoolFactory.java](/Users/zs/my-project/未命名文件夹/samples/passing/NamedThreadPoolFactory.java)

用途：

1. 验证默认规则不会误伤普通合规代码。
2. 验证 formatter 和 Checkstyle 对正常文件可稳定通过。

建议验证方式：

1. 让 Claude 根据样例内容尝试写入。
2. 观察是否出现预期的 deny / block。
3. 对照 `/hooks` 页面确认 Hook 已注册。

---

## 十一、下载、离线与内网镜像

这是第六项优化。

下载脚本： [`.claude/tools/download-jars.sh`](/Users/zs/my-project/未命名文件夹/.claude/tools/download-jars.sh)

当前支持两种方式：

### 1. 默认公网下载

```bash
.claude/tools/download-jars.sh
```

### 2. 内网镜像 / 手动覆盖

可通过环境变量覆盖：

```bash
P3C_URL=https://your-mirror/p3c-pmd.jar \
CHECKSTYLE_URL=https://your-mirror/checkstyle.jar \
GOOGLE_JAVA_FORMAT_URL=https://your-mirror/google-java-format.jar \
.claude/tools/download-jars.sh
```

也可以直接手工放入：

1. `.claude/p3c-pmd.jar`
2. `.claude/checkstyle.jar`
3. `.claude/google-java-format.jar`

交付建议：

1. 如果你的组织有制品库，优先把 `project-config.json` 里的 `download.*` 改成内网地址。
2. 如果是完全离线环境，直接把 Jar 跟模板一起打包交付。

---

## 十二、Windows 使用建议

这是第八项优化。

当前脚本默认 Bash + Python 3，最适合：

1. macOS
2. Linux
3. Windows + WSL

建议：

1. Windows 用户优先在 WSL 中运行 Claude Code 对应工作区。
2. 如果必须纯 PowerShell 运行，需要另补一套 `.ps1` 脚本实现。
3. 文档交付时请明确写清楚“推荐 WSL”，避免环境问题被误判成 Hook 问题。
4. 当前 `java-post-check.sh` 在 Windows 原生命令环境中会给出 WSL 友好提示。

---

## 十三、Hook 调试与排障

这是第九项优化。

### 1. 快速检查 Hook 是否注册

在 Claude Code 中执行：

```text
/hooks
```

### 2. 单脚本调试方法

#### 调试 `PreToolUse`

```bash
printf '%s' '{"tool_input":{"file_path":"/abs/path/Test.java","content":"public class Test { void x(){ System.out.println(1); } }"}}' \
  | .claude/hooks/java-pre-check.sh
```

#### 调试 `PostToolUse`

```bash
printf '%s' '{"tool_input":{"file_path":"/abs/path/Test.java"}}' \
  | .claude/hooks/java-post-check.sh
```

### 3. 一键验证脚本

文件： [`.claude/tools/verify-guardrail.sh`](/Users/zs/my-project/未命名文件夹/.claude/tools/verify-guardrail.sh)

执行：

```bash
chmod +x .claude/tools/verify-guardrail.sh
.claude/tools/verify-guardrail.sh
```

它会依次验证：

1. JSON 配置合法性
2. 规范文档渲染
3. Hook 脚本语法
4. XML 配置
5. 预检脚本
6. formatter
7. 写后 Hook
8. Checkstyle 结果

规范渲染脚本：

[`render-standards.sh`](/Users/zs/my-project/未命名文件夹/.claude/tools/render-standards.sh)

用途：

1. 根据 `project-config.json` 重新生成 [`.claude/java-coding-standards.md`](/Users/zs/my-project/未命名文件夹/.claude/java-coding-standards.md)。
2. 避免项目信息在配置和规范文档之间漂移。

---

## 十四、示例架构测试增强

这是第十项优化。

文件： [ArchitectureRuleTest.java](/Users/zs/my-project/未命名文件夹/src/test/java/com/example/demo/ArchitectureRuleTest.java)

当前除了原有规则，还增加了：

1. Controller 不得直接依赖 DAO / Mapper。
2. Service 不得依赖 Controller。

同时增加了显式常量：

1. `ROOT_PACKAGE`

使用时必须替换成真实项目根包名。

如果你的项目要更进一步，可继续加：

1. Controller 返回类型约束。
2. DTO / VO / Entity 边界约束。
3. 指定模块之间的 allowed dependency graph。

---

## 十五、落地步骤

1. 创建 `.claude`、`.claude/hooks`、`.claude/tools`、`.claude/state`、`samples/violations`、`samples/passing` 目录。
2. 将本文中的文件写入对应位置。
3. 修改 [`.claude/project-config.json`](/Users/zs/my-project/未命名文件夹/.claude/project-config.json)：
   项目名、根包名、JDK、镜像地址、最大修复轮次。
4. 根据团队红线维护 [`.claude/rule.md`](/Users/zs/my-project/未命名文件夹/.claude/rule.md)。
5. 执行：

```bash
chmod +x .claude/hooks/*.sh .claude/tools/*.sh
```

6. 先执行：

```bash
.claude/tools/render-standards.sh
```

7. 下载工具：

```bash
.claude/tools/download-jars.sh
```

8. 跑一遍：

```bash
.claude/tools/verify-guardrail.sh
```

9. 重启 Claude Code，并在项目中执行 `/hooks` 确认注册成功。

交付时建议同时附上：

1. [DELIVERY.md](/Users/zs/my-project/未命名文件夹/DELIVERY.md)
2. [CHECKLIST.md](/Users/zs/my-project/未命名文件夹/CHECKLIST.md)

---

## 十六、建议验证用例

### 用例 1：高危拦截

提示 Claude：

> 生成一个 Java 工具类，使用 Executors 创建线程池，并打印 System.out.println

预期：

1. `PreToolUse` 直接 deny。
2. Claude 根据理由改成 `ThreadPoolExecutor` 和日志框架。

### 用例 2：普通规范反馈

提示 Claude：

> 生成一个格式很差的 Java 方法，并 catch Exception

预期：

1. 文件会先被 formatter 处理。
2. 仍存在的 Checkstyle / P3C 问题会被返回给 Claude。
3. Claude 继续最小化修复。

### 用例 3：达到最大修复轮次

人为制造一个难以自动修掉的违规文件，多次触发写后校验。

预期：

1. `.claude/state/repair-state.json` 中轮次增加。
2. 达到上限后，反馈会要求 Claude 停止继续自动扩大修复范围，并通知用户人工接管。

---

## 十七、结论

这套方案当前已经不是“只有 Hook 和规则文件”的原型，而是一套可交付的 Java AI 规范闭环模板，具备：

1. 参数化配置中心。
2. 规则级开关。
3. 风险分层拦截。
4. 自动修复轮次控制。
5. 样例与验证材料。
6. 通过样例防误伤验证。
7. 离线 / 内网分发能力。
8. 保守版与严格版规范基线。
9. 规范渲染、调试和排障路径。
10. 规则治理与交付清单。

如果你的目标是“交给团队成员就能用、出了问题也能排、迁移到别的 Java 项目也不痛苦”，当前这版已经可以作为正式交付基线。
