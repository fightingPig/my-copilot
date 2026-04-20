# 构建与运行指南

本文档提供 ISMS6 项目的构建和运行命令参考。

## Build & Development Commands

### Build Project

```bash
# Full build with Maven
mvn clean install

# Package for deployment (produces zip in packageZip/)
mvn package

# Build with apps profile for deployment packages
mvn package -Papps
```

### Run Individual Module

Each module has its own Starter class, e.g.:
- `isms6-montmodu-server`: `com.hundsun.isms6.montmodu.MontModuStarter`
- `isms6-infomodu-server`: Similar pattern in respective package
