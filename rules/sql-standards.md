# SQL 标准规范

本文档定义 ISMS6 系统的 SQL 相关标准，包括数据库元数据参考和 SQL 脚本创建规则。

---

# 第一部分：数据库元数据参考

## 数据文件位置

当根据提示词或者设计方案，需要新建标准字段，或者新建标准数据字典，则需要根据业务需求，按需查询或修改数据库元数据文件：
1. 标准字段定义表中新建字段；
2. 标准数据字典定义表中新建字典条目。

```
E:\project-git\isms6-ares\元数据\metadata\
├── datatype.datatype      # 业务数据类型定义
├── stdfield.stdfield    # 标准字段定义
├── dict.dict            # 数据字典定义
├── defaulttype.defaulttype  # 标准数据类型映射
└── defaultvalue.defaultvalue # 默认值定义
```

---

## 新建标准字段操作说明

### 标准字段 XML 格式

```xml
<items xsi:type="metadata:StandardField" name="字段名" chineseName="中文名" description="字段说明" dataType="数据类型" status="修改">
  <data2 key="user">
    <value xsi:type="model:UserExtensibleProperty"/>
  </data2>
</items>
```

### 属性说明

| 属性 | 说明 | 示例 |
|------|------------|------------------------------|
| name | 字段名（英文） | delete_flag |
| chineseName | 中文名 | 删除标识 |
| description | 字段说明（可选） | 当记录删除时更新为失效时间戳 |
| dataType | 数据类型（Hs类型） | HsDateTime |
| status | 状态（新建时不填写） | 修改 |
| dictionaryType | 字典条目（可选） | 200079 |

### 注意事项

1. **字段说明使用 `description` 属性**，直接写在 items 标签上
2. **字典条目使用 `dictionaryType` 属性**，直接写在 items 标签上，该属性的值为字典条目的 item.name
3. `data2/user/value` 下保持为空，常规情况不需要添加子元素
4. **不要使用** `isused`、`used_detail`、`field_desc`、`defaultValue` 等属性

---

## 一、数据类型映射

### 标准类型到各数据库的映射

| 标准类型 | Oracle | MySQL | 说明 |
|----------|--------|-------|------|
| STDtinyInt | number(3,0) | tinyint | 整数 0-255 |
| STDsmallInt | number(5,0) | smallint | 整数 -32768~32767 |
| STDmediumInt | number(7,0) | mediumint | 整数 |
| STDint | number(10,0) | int | 整数 |
| STDbigInt | number(20,0) | bigint | 大整数 |
| STDdouble | number($L,$P) | decimal($L,$P) | 双精度浮点数 |
| STDlongdouble | number($L,$P) | decimal($L,$P) | 高精度浮点数 |
| STDchar | char | char | 单字符 |
| STDstr | varchar2($L) | varchar($L) | 字符串 |
| STDdate | number(8,0) | int | 日期（YYYYMMDD 整数） |
| STDtime | number(6,0) | int | 时间（HHMMSS 整数） |
| STDdatetime | number(14,6) | decimal | 日期时间 |
| STDBool | number(1,0) | tinyint | 布尔值 |
| STDlongtext | clob | longtext | 大文本 |

---

## 二、业务数据类型

### 常用字符串类型

| Hs类型 | 中文名 | Oracle类型 | 长度 | 使用场景 |
|--------|--------|-----------|------|----------|
| HsChar2 | 字符2 | varchar2(2) | 2 | 简码、状态码 |
| HsChar4 | 字符4 | varchar2(4) | 4 | 简拼、类型码 |
| HsChar8 | 字符8 | varchar2(8) | 8 | 短编码 |
| HsChar10 | 字符10 | varchar2(10) | 10 | 中编码 |
| HsChar16 | 字符16 | varchar2(16) | 16 | 编码、ID |
| HsChar18 | 字符18 | varchar2(18) | 18 | 身份证、股东账号 |
| HsChar20 | 字符20 | varchar2(20) | 20 | 长编码 |
| HsChar32 | 字符32 | varchar2(32) | 32 | 代码、编号 |
| HsChar64 | 字符64 | varchar2(64) | 64 | 名称、地址 |
| HsChar100 | 字符100 | varchar2(100) | 100 | 描述 |
| HsChar128 | 字符128 | varchar2(128) | 128 | 长描述 |
| HsChar255 | 字符255 | varchar2(255) | 255 | 备注、简介 |
| HsChar500 | 字符500 | varchar2(500) | 500 | 长备注、配置内容 |
| HsChar1000 | 字符1000 | varchar2(1000) | 1000 | 详细内容 |
| HsChar2000 | 字符2000 | varchar2(2000) | 2000 | 大段文本 |
| HsChar4000 | 字符4000 | varchar2(4000) | 4000 | 超大文本 |

### 常用整数类型

| Hs类型 | 中文名 | Oracle类型 | 长度 | 使用场景 |
|--------|--------|-----------|------|----------|
| HsInt8 | 整数2 | number(3,0) | 3 | 小整数、标志位 |
| HsInt16 | 整数4 | number(5,0) | 5 | 中整数、天数 |
| HsInt32 | 整数9 | number(10,0) | 10 | 普通整数、ID |
| HsInt64 | 整数19 | number(20,0) | 20 | 大整数、长ID |
| HsNType | 整数类型 | number(2,0) | 2 | 序号、类型 |

### 常用浮点数类型

| Hs类型 | 中文名 | Oracle类型 | 长度精度 | 使用场景 |
|--------|--------|-----------|---------|----------|
| HsPrice | 价格 | number(15,4) | 15,4 | 价格 |
| HsHighPrice | 高精度价格 | number(15,8) | 15,8 | 高精度价格 |
| HsRate | 低精度费率 | number(19,4) | 19,4 | 费率、汇率 |
| HsHighRate | 高精度费率 | number(19,12) | 19,12 | 高精度费率 |
| HsQuantity | 数量 | number(21,4) | 21,4 | 持仓数量 |
| HsCurrency | 金额 | number(19,2) | 19,2 | 资金金额 |
| HsShare | 份额 | number(19,6) | 19,6 | 基金份额 |
| HsLongDouble | 浮点数 | number(19,8) | 19,8 | 通用浮点 |

### 日期时间类型

| Hs类型 | 中文名 | Oracle类型 | 使用场景 |
|--------|--------|-----------|----------|
| HsDate | 日期 | number(8,0) | 业务日期、成立日期 |
| HsDateTime | 日期时间 | number(14,6) | 操作时间、更新时间 |
| HsTime | 时间 | number(6,0) | 时间点 |

### 业务专用类型

| Hs类型 | 中文名 | Oracle类型 | 使用场景 |
|--------|--------|-----------|----------|
| HsFundID | 产品内部序号 | number(12,0) | 产品ID |
| HsFundCode | 产品代码 | varchar2(32) | 产品代码 |
| HsSecurityCode | 证券代码 | varchar2(32) | 证券代码 |
| HsMarketID | 市场代码 | number(2,0) | 市场ID |
| HsCurrency | 币种 | varchar2(3) | 币种代码 |
| HsAccountCode | 账户号 | varchar2(32) | 账户编号 |
| HsClientNo | 客户编号 | varchar2(18) | 客户编号 |
| HsInstCode | 机构编码 | varchar2(32) | 机构代码 |
| HsSerialID | 流水号 | number(16,0) | 流水号 |
| HsBool | 是否标志 | number(1,0) | 是/否 |
| HsFlag | 标志 | char(1) | 状态标志 |
| HsStatus | 状态 | char(1) | 状态 |

---

## 三、标准字段

### 公共字段

| 字段名 | 中文名 | 数据类型 | 数据字典 | 说明 |
|--------|--------|---------|---------|------|
| rec_id | 记录ID | HsInt64 | - | 主键 |
| create_time | 创建时间 | HsDateTime | - | - |
| create_prsn | 创建人 | HsChar64 | - | - |
| update_time | 更新时间 | HsDateTime | - | - |
| update_prsn | 更新人 | HsChar64 | - | - |
| operate_time | 操作时间 | HsDateTime | - | - |
| operate_prsn | 操作人 | HsChar64 | - | - |
| valid_flag | 是否有效状态 | HsFlag | 400001 | 1:是 0:否 |
| display_flag | 显示标识 | HsNType | - | 1:显示 0:不显示 |
| delete_flag | 删除标识 | HsDateTime | - | 记录删除时更新为失效时间戳，>0表示已失效 |
| remark | 备注 | HsChar500 | - | - |
| sort_order | 排序号 | HsInt32 | - | - |

### 产品相关字段

| 字段名 | 中文名 | 数据类型 | 数据字典 | 说明 |
|--------|--------|---------|---------|------|
| fund_id | 产品ID | HsFundID | - | 产品内部序号 |
| fund_code | 产品代码 | HsFundCode | - | - |
| fund_name | 产品名称 | HsName256 | - | - |
| fund_fullname | 产品全称 | HsName256 | - | - |
| fund_type | 产品类型 | HsNType | 100001 | 公募/私募等 |
| fund_style | 产品风格 | HsNType | 200078 | - |
| fund_invest | 产品投资性质 | HsNType | 200079 | - |
| fund_operation | 产品运作方式 | HsNType | 100004 | - |
| market_no | 交易市场 | HsInt16 | 201101 | - |
| register_date | 成立日期 | HsDate | - | - |
| maturity_date | 到期日期 | HsDate | - | - |

---

## 四、常用数据字典

### 公共类字典

| 字典编码 | 字典名称 | 说明 |
|----------|----------|------|
| 400001 | 是否标志 | 1:是 0:否 |
| 400002 | 数据来源 | - |
| 400003 | 风险等级 | - |
| 400004 | 预警方向 | - |
| 400005 | 监控结果状态 | - |

### 产品类字典

| 字典编码 | 字典名称 | 说明 |
|----------|----------|------|
| 100001 | 产品类型 | 1:公募基金 2:私募基金 3:专户理财 ... |
| 100004 | 产品运作方式 | 1:开放式 2:封闭式 ... |
| 100005 | 产品募集方式 | - |
| 100006 | 资管计划类型 | - |
| 200078 | 产品风格 | - |
| 200079 | 产品投资性质 | - |

### 市场类字典

| 字典编码 | 字典名称 | 说明 |
|----------|----------|------|
| 201101 | 交易市场 | 1:上海 2:深圳 5:沪市转债 ... |

---

## 五、建表字段选择指南

### 字段类型选择原则

1. **主键**：使用 `HsInt64` (number(20,0))，自增或分布式ID
2. **时间**：使用 `HsDateTime` (number(14,6)) 存储精确时间
3. **日期**：使用 `HsDate` (number(8,0)) 存储 YYYYMMDD 格式日期
4. **金额**：使用 `HsCurrency` (number(19,2)) 或 `HsLongDouble`
5. **数量**：使用 `HsQuantity` (number(21,4))
6. **价格/汇率**：使用 `HsPrice` (number(15,4)) 或 `HsHighRate`
7. **代码/编号**：使用 `HsChar32` 或合适长度
8. **名称**：使用 `HsName64` / `HsName128` / `HsName256`
9. **状态/标志**：使用 `HsFlag` (char) 或 `HsNType`
10. **描述/备注**：使用 `HsChar255` / `HsChar500`

### 必填公共字段

建议所有表都包含以下字段：

```sql
rec_id          number(20,0)   -- 记录ID（主键）
create_time     number(14,6)   -- 创建时间
create_prsn     varchar2(64)   -- 创建人
modify_time     number(14,6)   -- 更新时间
modify_prsn     varchar2(64)   -- 更新人
valid_flag      char(1)        -- 有效标志（1:有效 0:无效）
```

### Oracle 表结构示例

```sql
CREATE TABLE example_table (
    rec_id          number(20,0)   DEFAULT 0 NOT NULL,
    fund_code       varchar2(32)   DEFAULT ' ' NOT NULL,
    fund_name       varchar2(256)  DEFAULT ' ' NOT NULL,
    fund_type       number(2,0)    DEFAULT 0 NOT NULL,
    nav_date        number(8,0)    DEFAULT 0 NOT NULL,
    nav             number(15,4)   DEFAULT 0 NOT NULL,
    asset           number(19,2)  DEFAULT 0 NOT NULL,
    amount          number(21,4)   DEFAULT 0 NOT NULL,
    remark          varchar2(500)  DEFAULT ' ',
    create_time     number(14,6)  DEFAULT 0 NOT NULL,
    create_prsn     varchar2(64)   DEFAULT ' ' NOT NULL,
    modify_time     number(14,6)  DEFAULT 0 NOT NULL,
    modify_prsn     varchar2(64)   DEFAULT ' ' NOT NULL,
    valid_flag      char(1)       DEFAULT '1' NOT NULL,
    CONSTRAINT example_table_pk PRIMARY KEY (rec_id)
);

CREATE INDEX example_table_n1 ON example_table(fund_code ASC);
CREATE INDEX example_table_n2 ON example_table(nav_date ASC);
```

---

## 六、特殊字段处理

### 时间字段格式

ISMS6 系统使用数值型时间：
- **日期**：number(8,0)，格式 YYYYMMDD，如 20260310
- **时间**：number(6,0)，格式 HHMMSS，如 103000
- **日期时间**：number(14,6)，格式 YYYYMMDDHHMMSS.ffffff

### 主键策略

- 使用 `@IdType.ASSIGN_ID` + `@KeySequence` + `@GlobalSequence`
- Java 类型使用 `Long`
- 数据库类型使用 `number(20,0)`

### 外键策略

- 禁止使用外键

### NULL 值处理

- 字符型：`DEFAULT ' ' NOT NULL`（空字符串而非 NULL）
- 数值型：`DEFAULT 0 NOT NULL`
- 日期型：`DEFAULT 0 NOT NULL`

---

# 第二部分：SQL 脚本创建规则

## 一、目录结构

```
模块名/
└── deploy/
    └── sqls/
        ├── dm/                 # 达梦数据库
        │   ├── default/        # ISMS6系统业务表结构
        │   └── bizframe/       # 用户权限系统脚本（辅助系统）
        ├── oracle/             # Oracle 数据库
        ├── mysql/              # MySQL 数据库(已废弃，不再维护)
        ├── oboracle/          # OceanBase-Oracle数据库数据库
        └── gaussdbopengauss/  # GaussDB OpenGauss 数据库
```

### 子目录说明

| 子目录 | 说明 |
|--------|------|
| `default` | 存放基础表结构的 DDL 和初始数据的 DML |
| `bizframe` | 存放业务框架相关的 SQL（如组件配置等） |

## 二、版本号目录

版本号目录位于 `{数据库类型}/default/` 或 `{数据库类型}/bizframe/` 目录下。

### 版本号格式

**格式一（早期版本）**：
```
1.0.0, 1.1.0, 1.2.0, ..., 1.9.0
```

**格式二（后期版本，YYYYMM.NN.NNN）**：
```
202205.00.000, 202206.01.004, ..., 202601.00.000M1
```

### 版本号命名规则

1. 版本号从 `pom.xml` 中获取，去掉末尾的 `-snapshot` 等后缀
2. `default` 和 `bizframe` 目录都使用相同的版本号

## 三、SQL 文件命名规则

### 命名格式

```
{YYYYMMDD}_{DDL|DML}_{表名}_v{版本序号}.sql
```

### 组成部分

| 部分 | 说明 | 示例 |
|------|------|------|
| YYYYMMDD | 创建日期（8位数字） | 20260309 |
| DDL/DML | 操作类型 | DDL（表结构）、DML（数据操作） |
| 表名 | 相关的表名 | TP_Parameter、FundNavParameter |
| 版本序号 | 版本号，从01开始 | v01, v02, v03 |

### 示例

```
20260309_DDL_TP_Parameter_v01.sql    # DDL：创建TP_Parameter表
20260309_DML_TP_Parameter_v01.sql    # DML：插入TP_Parameter数据
```

## 四、SQL 文件内容规范

### DDL 文件（表结构）

```sql
-- -----------------------------------------------
-- 全量脚本
-- -----------------------------------------------
-- 创建表 {表名}({表说明})的当前表
prompt Create Table '{表名}' {表说明}...
declare
    v_rowcount number(10);
    v_sql varchar2(1500);
begin
    select count(*) into v_rowcount from dual where exists(select * from user_objects where object_name = upper('{表名}'));
    if v_rowcount = 0 then
        v_sql := 'CREATE TABLE {表名}(' ||
                 '字段1  varchar2(32)    DEFAULT '||chr(39)||chr(32)||chr(39)||'        NOT NULL,' ||
                 ...
                 ')';
        execute immediate v_sql;
        execute immediate 'ALTER TABLE {表名} ADD CONSTRAINT {表名}_PK PRIMARY KEY(主键)';
        execute immediate 'CREATE INDEX {表名}_N1 ON {表名}(字段 ASC )';
    end if;
end;
commit;
```

**关键点**：
- 使用 PL/SQL 块进行条件判断（判断表是否存在）
- 字段定义使用动态 SQL 构建
- **禁止使用 `/` 结束块**
- 如需提交，使用 `commit;`

### DML 文件（数据操作）

```sql
-- {表说明}
-- 创建时间: {YYYY/MM/DD}
-- 功能: {功能描述}

declare
    v_cnt int;
begin
    select count(1) into v_cnt from all_tables where owner = upper('{Schema名}') and table_name = upper('{表名}');
    if v_cnt = 1 then
        -- {字段说明}
        select count(1) into v_cnt FROM {表名} WHERE {条件字段} = '{值}';
        if v_cnt = 0 then
            INSERT INTO {表名}(字段1, 字段2, ...)
            VALUES (值1, 值2, ...);
        end if;

        -- 多个数据...
    end if;
end;
commit;
```

**关键点**：
- 文件头部注释说明创建时间、功能
- 使用 PL/SQL 块进行幂等性检查（先判断记录是否存在）
- 条件判断表是否存在
- **禁止使用 `/` 结束块**
- 最后使用 `commit;` 提交

## 五、创建 SQL 脚本的步骤

### 1. 确定目标数据库和版本

根据需求确定：
- 哪个模块（fundmodu、pubmodu、montmodu 等）
- 必须生成oracle、dm、oboracle（OceanBase-Oracle）、gaussdbopengauss 四个数据库类型的脚本，创建脚本时，将脚本放在对应数据库类型的目录下
- mysql脚本已废弃，不在维护，不需要创建mysql脚本。
- dm数据库脚本的sql文件，必须使用GBK编码保存，其他数据库脚本的sql文件，必须使用UTF-8编码保存。
- 哪个子目录（default 或 bizframe）
- 哪个版本号目录

### 2. 确定 SQL 类型

- **DDL**：创建表、修改表结构、创建索引等
- **DML**：插入数据、更新数据等

### 3. 编写 SQL 文件

按照上述规范编写 SQL 内容。

### 4. 命名文件

```
{YYYYMMDD}_{DDL|DML}_{表名}_v{序号}.sql
```

## 六、示例

### 示例 1：为 pubmodu 模块的数据库创建参数表 DDL

**路径**：
```
isms6-system-apps/pubmodu/isms6-pubmodu-server/deploy/sqls/oracle/default/202601.00.000M1/
isms6-system-apps/pubmodu/isms6-pubmodu-server/deploy/sqls/dm/default/202601.00.000M1/
isms6-system-apps/pubmodu/isms6-pubmodu-server/deploy/sqls/oboracle/default/202601.00.000M1/
isms6-system-apps/pubmodu/isms6-pubmodu-server/deploy/sqls/gaussdbopengauss/default/202601.00.000M1/
```

**文件名**：
```
20260309_DDL_TP_FundConfig_v01.sql
```

### 示例 2：为 pubmodu 模块的数据库插入配置数据 DML

**路径**：
```
isms6-system-apps/pubmodu/isms6-pubmodu-server/deploy/sqls/oracle/default/202601.00.000M1/
isms6-system-apps/pubmodu/isms6-pubmodu-server/deploy/sqls/dm/default/202601.00.000M1/
isms6-system-apps/pubmodu/isms6-pubmodu-server/deploy/sqls/oboracle/default/202601.00.000M1/
isms6-system-apps/pubmodu/isms6-pubmodu-server/deploy/sqls/gaussdbopengauss/default/202601.00.000M1/
```

**文件名**：
```
20260309_DML_TP_FundConfig_v01.sql
```

## 七、注意事项

1. **幂等性**：所有 DML 操作必须先检查数据是否已存在，避免重复插入
2. **兼容性**：同一功能的 SQL 需要在多种数据库类型目录下都创建（如 oracle、dm、gaussdbopengauss、oboracle（OceanBase-Oracle） 等）
3. **版本管理**：同一次需求/缺陷修改的 SQL 放在同一个版本目录下
4. **顺序执行**：DDL 先执行，创建表结构；DML 后执行，插入初始数据
