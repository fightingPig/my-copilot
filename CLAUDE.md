# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **注意**: 本文件已拆分为多个子文件，按需加载。请查看下方「子文件说明」了解各文件的加载场景。

---

## 子文件说明

本项目的规则文档拆分为以下子文件，位于 `.claude/rules/` 目录：

| 子文件 | 加载场景 |
|--------|----------|
| [build.md](.claude/rules/build.md) | 构建项目、运行模块时 |
| [architecture.md](.claude/rules/architecture.md) | 了解项目结构、模块划分时 |
| [code-standards.md](.claude/rules/code-standards.md) | 开发新功能、代码生成、重构时 |
| [sql-standards.md](.claude/rules/sql-standards.md) | 创建数据库表、编写SQL脚本时 |
| [sequence.md](.claude/rules/sequence.md) | 配置主键序列、全局序列、IDGenerator时 |
| [permission-script.md](.claude/rules/permission-script.md) | 生成菜单、接口权限初始化脚本时 |

---

## 快速索引

### 需要构建/运行项目？
→ 加载 [build.md](.claude/rules/build.md)

### 需要了解项目架构？
→ 加载 [architecture.md](.claude/rules/architecture.md)

### 需要开发新功能或生成代码？
→ 加载 [code-standards.md](.claude/rules/code-standards.md)

- 六层架构规范
- Entity/Mapper/Manage/Service/API 层职责
- Controller 使用规范
- Request/Response 命名规范
- 历史代码重构规范
- 代码生成模板

### 需要创建数据库表或SQL脚本？
→ 加载 [sql-standards.md](.claude/rules/sql-standards.md)

- 数据库元数据参考
- 数据类型映射
- 标准字段定义
- 数据字典
- SQL 脚本创建规则

### 需要配置主键序列？
→ 加载 [sequence.md](.claude/rules/sequence.md)

- 普通序列配置（数据库自增序列）
- 全局序列配置（组合表场景）
- IDGenerator.json 配置
- TGlobalSequence 表数据插入

### 需要生成菜单、接口权限脚本？
→ 加载 [permission-script.md](.claude/rules/permission-script.md)

- 权限脚本结构（6个部分）
- 各表字段说明
- 子功能项定义
- 文件命名规范
- 版本号从 pom.xml 获取

---

## 常用命令速查

```bash
# 构建项目
mvn clean install

# 打包部署
mvn package -Papps

# 运行模块（参考 build.md 中的 Starter 类）
```

## 可审核列表增删改查方案涉及到的改动内容
- 审核开启配置：参考isms6-system-apps/pubmodu/isms6-pubmodu-server/src/main/resources/config/ModuleVerify.xml
- 全局序列配置：参考 [sequence.md](.claude/rules/sequence.md) 规则文档
- 代码框架配置：参考isms6-system-apps/montmodu/isms6-montmodu-server/src/main/java/com/hundsun/isms6/montmodu/securitypoolmanage/service/SecurityPoolServiceImpl.java
- 注意：代码框架核心在实现ServiceHsImpl接口，需在实现类中实现对应方法。但是参考代码分层架构不符合规范，新生成的代码需要遵循新的架构规范。