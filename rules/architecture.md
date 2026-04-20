# 架构概述

本文档提供 ISMS6 项目的架构概述和设计规范。

## Project Structure

This is an investment supervision business system (投资监督业务系统) built with Spring Boot 2.6.2 and Java 8.

**Layered Architecture:**
```
isms6-system/
├── isms6-system-apps/          # Business modules layer
│   ├── fundmodu/               # Fund module (产品/基金相关)
│   ├── infomodu/               # Information module (信息管理)
│   ├── montmodu/               # Monitoring module (监控/合规监控)
│   ├── pubmodu/                # Public module (公共功能)
│   ├── repmodu/                # Report module (报表)
│   └── oldsystemmodu/          # Legacy system integration
├── isms6-system-booter/        # Application booter (统一启动层)
├── isms6-system-support/       # Common utilities and support (isms6-common)
└── isms6-system-database/      # Database layer (currently disabled in parent pom)
```

## Module Structure

Each business module follows this pattern:
```
module-name/
├── module-name-api/      # Service interfaces, models, DTOs
└── module-name-server/   # Service implementation, controllers, business logic
```

## Key Dependencies

- **Framework**: Spring Boot 2.6.2, JResCloud (Hundsun's internal framework)
- **Database**: MyBatis-Plus, support for Oracle, MySQL, Dameng (达梦), GaussDB, OceanBase
- **RPC**: JResCloud RPC for inter-module communication
- **Application Servers**: TongWeb (东方通), BES (宝兰德)
- **Template Engine**: FreeMarker
- **Excel**: Apache POI
- **PDF**: iText, fr.opensagres (for Word/PDF conversion)

## Conventions

- Package naming: `com.hundsun.isms6.<module>.<layer>`
- Service interfaces annotated with `@CloudService`
- RPC methods return `RpcResultDTO<T>`
- MyBatis mappers use `tk.mybatis` (generic mapper framework)
- Lombok used extensively for boilerplate reduction
- Tests are skipped by default (`skipTests=true`)

## Git Hooks

Commit template available at `.githooks/commit-template.txt` with fields for:
- 修改单编号 (Change request number)
- 缺陷编号 (Defect number)
- 任务编号 (Task number)
- 需求编号 (Requirement number)
- 修改补充说明 (Additional description)
