# 序列配置规范

本文档定义 ISMS6 系统中主键序列的两种配置模式。

---

## 模式一：普通序列

### 适用场景

单表（非组合表），使用数据库自增序列，序列名为 `表名 + _s`。

### 配置步骤

#### 1. Entity 注解配置

```java
@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("tm_rule")
@KeySequence("mybatisGenerator")
@GlobalSequence(value = "tm_rule_s")  // 默认 type = DATABASE，序列名为 表名_s
public class Rule implements Serializable {

    @TableId(value = "rec_id", type = IdType.ASSIGN_ID)
    private Long recId;

    // ... 其他字段
}
```

**说明**：
- `@GlobalSequence(value = "表名_s")` 不写 type 时默认为 `DATABASE`，序列名为 `表名 + _s`
- `@KeySequence("mybatisGenerator")` 固定写法，用于 MyBatis Generator 生成器

#### 2. DDL 脚本配置

在创建表的 DDL 脚本末尾，创建对应的数据库序列：

```sql
-- 创建表 tm_rule ...
-- ... (建表语句)

-- 创建序列
execute immediate 'create sequence tm_rule_s';
```

**完整 DDL 示例**：

```sql
prompt Create Table 'tm_rule' 规则表......
declare
    v_rowcount number(10);
    v_sql varchar2(10000);
begin
    select count(*) into v_rowcount from dual where exists(select * from user_objects where object_name = upper('tm_rule'));
    if v_rowcount = 0 then
        v_sql := 'CREATE TABLE tm_rule(' ||
                 'rec_id         number(20,0)    NOT NULL,' ||
                 'rule_name      varchar2(256)   DEFAULT '' ''    NOT NULL' ||
             ')';
        execute immediate v_sql;
        execute immediate 'ALTER TABLE tm_rule ADD CONSTRAINT tm_rule_pk PRIMARY KEY(rec_id)';

        -- 创建序列
        execute immediate 'create sequence tm_rule_s';
    end if;
end;
/
```

#### 3. 关键点

| 项目 | 说明 |
|------|------|
| 注解 | `@GlobalSequence(value = "表名_s")` + `@KeySequence("mybatisGenerator")` |
| 序列名 | `表名 + _s`（如 `tm_rule` 表对应 `tm_rule_s` 序列） |
| IDGenerator.json | 不需要配置 |
| DDL 脚本 | 在建表脚本末尾通过 `create sequence 表名_s;` 创建 |

---

## 模式二：全局序列（组合表）

### 适用场景

**组合表**情况：主表 + 主表 `_modify` 表，这两个表公用一个全局序列。

例如：
- `tm_plan_fund`（主表）+ `tm_plan_fund_modify`（变更表）
- `tm_investpoolsecuinfo`（主表）+ `tm_investpoolsecuinfo_modify`（变更表）

### 配置步骤

#### 1. Entity 注解配置

**主表 Entity**：

```java
@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("tm_plan_fund")
@KeySequence("mybatisGenerator")
@GlobalSequence(value = "tm_plan_fund", type = GlobalSequence.GLOBAL)
public class PlanFund implements Serializable {

    @TableId(value = "rec_id", type = IdType.ASSIGN_ID)
    private Long recId;

    // ... 其他字段
}
```

**变更表 Entity**（`_modify` 后缀）：

```java
@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("tm_plan_fund_modify")
@KeySequence("mybatisGenerator")
@GlobalSequence(value = "tm_plan_fund", isModify = true, type = GlobalSequence.GLOBAL)
public class PlanFundModify implements Serializable {

    @TableId(value = "rec_id", type = IdType.ASSIGN_ID)
    private Long recId;

    // ... 其他字段
}
```

#### 2. IDGenerator.json 配置

在模块的 `IDGenerator.json` 中添加序列映射：

```json
{
  "type": "DATABASE",
  "providers": [
    {
      "id": 0
    }
  ],
  "sequences": [
    {
      "name": "tm_plan_fund",
      "key": "isms6:sequence:tm_plan_fund"
    },
    {
      "name": "tm_plan_fund_modify",
      "key": "isms6:sequence:tm_plan_fund"
    }
  ]
}
```

**注意**：
- 主表和 `_modify` 表的 `key` 必须相同（指向同一个全局序列）
- `name` 为表名（实际存储在 `TGlobalSequence` 表中的 `sequence_name`）

#### 3. DML 脚本配置

需要通过 DML 脚本将序列插入到 `TGlobalSequence` 表中。

**DML 文件命名**：
```
{YYYYMMDD}_DML_Tglobalsequence_v{序号}.sql
```

**SQL 内容示例（Oracle）**：

```sql
declare
    v_rowcount number(10);
    v_maxid number(10);
    v_minid number(10);
begin
    select count(1) into v_rowcount FROM user_tab_columns where TABLE_NAME = upper('tglobalsequence');

    if v_rowcount > 0 THEN
        -- isms6:sequence:tm_plan_fund
        select count(1) into v_rowcount from tglobalsequence where sequence_name = 'isms6:sequence:tm_plan_fund';
        if v_rowcount = 0 then
            select nvl(max(rec_id), 10001) into v_maxid from tm_plan_fund where rec_id < 100000000;
            select nvl(max(rec_id), 10001) into v_minid from tm_plan_fund_modify where rec_id < 100000000;

            if v_maxid < v_minid then
                v_maxid := v_minid + 1;
            else
                v_maxid := v_maxid + 1;
            end if;

            insert into tglobalsequence (SEQUENCE_NAME, CURRENT_VALUE, BUFFER_SIZE, COMMENTS)
            values ('isms6:sequence:tm_plan_fund', v_maxid, 1E19, '方案关联基金');
        end if;

        commit;
    end if;
end;
/
```

**DML 文件存放路径**：
```
{module-name-server}/deploy/sqls/{database-type}/default/{version}/20240424_DML_Tglobalsequence_v01.sql
```

需要为以下数据库类型都创建 DML 脚本：
- `oracle`
- `dm`
- `oboracle`（OceanBase-Oracle）
- `gaussdbopengauss`

**注意**：
- `mysql` 脚本已废弃，不再维护
- `dm` 数据库脚本必须使用 **GBK** 编码保存
- 其他数据库脚本必须使用 **UTF-8** 编码保存

#### 4. 关键点

| 项目 | 说明 |
|------|------|
| 主表注解 | `@GlobalSequence(value = "主表名", type = GlobalSequence.GLOBAL)` |
| _modify 表注解 | `@GlobalSequence(value = "主表名", isModify = true, type = GlobalSequence.GLOBAL)` |
| IDGenerator.json | 主表和 _modify 表配置相同的 `key` |
| DML 脚本 | 插入序列到 `TGlobalSequence` 表，`sequence_name` 格式为 `isms6:sequence:主表名` |

---

## 注解参数说明

### @GlobalSequence 参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| value | String | "" | 序列名称（通常为主表名） |
| isModify | boolean | false | 是否为变更表（_modify 表设为 true） |
| type | String | DATABASE | 序列类型：`GLOBAL`（全局序列）或 `DATABASE`（普通序列） |
| dbTemplate | String | "default" | 数据库源 |

### @KeySequence 参数

| 参数 | 说明 |
|------|------|
| value | MyBatis Generator 模板名称，固定使用 `"mybatisGenerator"` |

---

## 判断流程

```
新建表/Entity
       ↓
是否为组合表（主表 + 主表_modify）？
       ↓
    是 → 使用模式二：全局序列
         - Entity 配置 @GlobalSequence(value = "主表名", isModify = true/false, type = GlobalSequence.GLOBAL)
         - 配置 IDGenerator.json（主表和 _modify 表映射到相同 key）
         - 创建 DML 脚本插入 TGlobalSequence 表
       ↓
    否 → 使用模式一：普通序列
         - Entity 配置 @GlobalSequence(value = "表名")
         - 在 DDL 建表脚本末尾创建序列：create sequence 表名_s;
```

---

## TGlobalSequence 表结构

```sql
CREATE TABLE tglobalsequence(
    sequence_name   varchar2(60)    DEFAULT ' '    NOT NULL,
    current_value   number(20,0)   DEFAULT 0       NOT NULL,
    buffer_size     number(20,0)   DEFAULT 0       NOT NULL,
    comments        varchar2(200)  DEFAULT ' '     NOT NULL
);
```

| 字段 | 说明 |
|------|------|
| sequence_name | 序列名称，格式为 `isms6:sequence:主表名` |
| current_value | 当前序列值 |
| buffer_size | 缓冲大小 |
| comments | 序列说明（中文描述） |

---

## 两种模式对比

| 项目 | 普通序列（模式一） | 全局序列（模式二） |
|------|-------------------|-------------------|
| 适用场景 | 单表 | 组合表（主表 + 主表_modify） |
| @GlobalSequence | `@GlobalSequence(value = "表名_s")` | `@GlobalSequence(value = "主表名", isModify = true/false, type = GlobalSequence.GLOBAL)` |
| 序列创建 | DDL 建表脚本末尾 `create sequence 表名_s;` | DML 脚本插入 TGlobalSequence 表 |
| IDGenerator.json | 不需要配置 | 需要配置主表和 _modify 表映射 |
| 序列名 | `表名 + _s` | `isms6:sequence:主表名` |
