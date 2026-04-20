# Java 编码规范

## 项目基线

- JDK：8
- Spring Boot：3.2.x
- 持久层：MyBatis-Plus 3.5.x
- 架构：layered
- 日志框架：SLF4J

## 强制规则

### 异常处理

1. 禁止捕获通用 `Exception` 或 `Throwable`，必须捕获具体异常。
2. 禁止只打印 `e.getMessage()`，记录异常时必须保留堆栈。
3. 禁止在 `finally` 中 `return`。
4. 禁止吞异常。

### 并发与线程池

1. 禁止使用 `Executors` 快捷工厂创建线程池。
2. 禁止直接创建裸线程 `new Thread(...)`。
3. `ThreadLocal` 使用后必须在 `finally` 中 `remove()`。
4. `Lock` 的 `unlock()` 必须放在 `finally` 中。

### 空值与数据类型

1. POJO 中的 `Boolean` 属性禁止以 `is` 开头命名。
2. 禁止使用 `==` 比较包装类。
3. 使用集合、数组前必须先判空。

### SQL 与持久层

1. MyBatis 参数绑定禁止直接使用 `${}`。
2. 禁止全表更新、全表删除。
3. 禁止 `select *`。
4. DAO 层只做数据访问，不承载业务逻辑。

### 安全

1. 禁止硬编码密码、Token、AK/SK、密钥。
2. 禁止使用 `System.out.println` 或 `System.err.println` 打印业务日志。
3. 接口入参必须校验后再使用。

## AI 修复要求

1. 优先最小修复，只改违规点。
2. 不修改无关业务逻辑。
3. 修复后若再次触发校验，继续按违规列表逐项修复。
