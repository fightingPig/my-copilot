# 代码生成标准

本文档定义 ISMS6 项目的代码生成标准和分层架构规范。

## 标准分层架构

新开发的功能应遵循以下六层架构（以 `word` 模块为参考）：

```
module-name/
├── module-name-api/                      # API 层（独立子模块）
│   └── src/main/java/com/hundsun/isms6/<module>/api/
│       ├── <feature>/
│       │   ├── model/                    # DTO/请求响应模型
│       │   └── service/                  # @CloudService 接口定义
└── module-name-server/                   # Server 层（实现子模块）
    └── src/main/java/com/hundsun/isms6/<module>/
        ├── <feature>/
        │   ├── entity/                   # 实体层 - 数据库表映射
        │   ├── mapper/                   # 数据访问层 - MyBatis Mapper
        │   ├── manage/                   # 业务管理层 - 复杂业务逻辑
        │   ├── service/                  # RPC 服务层 - 对外暴露接口
        │   └── help/                     # 辅助层 - 跨实体业务协调 (可选)
        └── src/main/resources/
            ├── mapper/<database-type>/<feature>/   # MyBatis XML 映射文件
```

---

## 各层职责与规范

### 1. Entity 层 (`entity/`)

**职责**: 数据库表映射

**规范**:
- 使用 MyBatis-Plus 注解：`@TableName`, `@TableId`, `@TableField`
- 使用 Lombok: `@Data`, `@EqualsAndHashCode`, `@Accessors(chain = true)`
- 实现 `Serializable`
- 主键策略：`IdType.ASSIGN_ID` + `@KeySequence` + `@GlobalSequence`
- 命名：`<TableName>Model.java`

**示例**:
```java
@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@TableName("TM_Words")
@KeySequence("mybatisGenerator")
@GlobalSequence(value = "TM_Words_s")
public class WordModel implements Serializable {
    private static final long serialVersionUID = 1L;

    @TableId(value = "rec_id", type = IdType.ASSIGN_ID)
    private Long recId;

    @TableField("word_name")
    private String wordName;

    @TableField("word_desc")
    private String wordDesc;
}
```

**Entity 字段规范**:
- String 类型字段必须添加 `typeHandler` 和 `jdbcType`：
```java
@TableField(value = "field_name", typeHandler = NullValueHandler.class, jdbcType = JdbcType.VARCHAR)
private String fieldName;
```
- 不要使用 `insertStrategy = FieldStrategy.NOT_EMPTY`

---

### 2. Mapper 层 (`mapper/`)

**职责**: 数据访问，自定义 SQL 查询

**规范**:
- 注解：`@Repository` + `@Mapper`
- 继承：`BaseMapper<T>`
- 自定义 SQL 写在 XML 文件，不写在注解中
- 命名：`<Feature>Mapper.java`
- XML 路径：`src/main/resources/mapper/<database-type>/<feature>/<MapperName>.xml`

**示例**:
```java
@Repository
@Mapper
public interface WordMapper extends BaseMapper<WordModel> {
    List<WordModel> selectListByWordNames(@Param("wordNames") List<String> wordNames);
}
```

---

### 3. Manage 层 (`manage/`)

**职责**: 单表业务逻辑 + 复杂查询封装

**规范**:
- 注解：`@Component`
- 继承：`ServiceImpl<Mapper, Entity>`
- 可注入同层其他 Manage 或 Mapper
- 不直接对外暴露，供 Service 层和 Help 层调用
- 命名：`<Feature>Manage.java`

**示例**:
```java
@Component
public class WordManage extends ServiceImpl<WordMapper, WordModel> {

    @Resource
    private WordMapper wordMapper;

    public List<WordModel> matchByDesc(String desc) {
        if (StringUtils.isBlank(desc)) {
            return Collections.emptyList();
        }
        List<WordModel> wordModels = baseMapper.selectList(new QueryWrapper<>());
        // ... 业务逻辑
        return newWordModels;
    }

    public List<WordModel> listByIds(List<Long> ids) {
        if (CollectionUtils.isEmpty(ids)) {
            return Collections.emptyList();
        }
        return baseMapper.selectBatchIds(ids);
    }
}
```

---

### 4. Help 层 (`help/` - 可选)

**职责**: 跨多表/多实体的业务协调

**规范**:
- 注解：`@Component`
- 注入多个 Manage 完成复杂业务
- 仅在内使用，不对外暴露
- 命名：`<Feature>Helper.java`

**使用场景**:
- 单表 CRUD → **不使用** Help 层，Manage 层直接处理
- 跨多表业务协调 → **使用** Help 层

**示例**:
```java
@Component
public class RuleBaseKeyWordHelper {

    @Resource
    private WordManage wordManage;
    @Resource
    private RuleBaseKeyWordManage ruleBaseKeyWordManage;

    public void addRuleBaseKeyWordsAndDeleteOld(Long ruleBaseRecId, List<RuleBaseKeyWordModelTemp> keyWordModelTemp) {
        // 跨表业务逻辑：同时操作 Word 表和 KeyWord 关联表
        // 1. 检查词库是否存在，不存在则新增
        // 2. 建立规则模板与词条的关联关系
    }
}
```

---

### 5. Service 层 (`service/`)

**职责**: RPC 服务暴露，仅负责数据转换和 RPC 包装

**规范**:
- 注解：`@CloudComponent`
- 实现 API 层定义的接口
- 返回类型：`RpcResultDTO<T>`
- **不包含复杂业务逻辑**，业务逻辑委托给 Manage 层
- **禁止直接注入 Mapper**，必须通过 Manage 层间接操作数据库
- 命名：`<Feature>ServiceImpl.java`

**示例**:
```java
@CloudComponent
public class WordServiceImpl implements WordService {

    @Resource
    private WordManage wordManage;

    @Override
    public RpcResultDTO<List<WordModelResponse>> matchByDesc(DescModel descModel) {
        String desc = descModel.getDesc();
        List<WordModel> wordModels = wordManage.matchByDesc(desc);

        // 数据模型转换
        List<WordModelResponse> responseList = wordModels.stream()
            .map(v -> {
                WordModelResponse response = new WordModelResponse();
                BeanUtils.copyProperties(v, response);
                response.setWordId(v.getRecId());
                return response;
            }).collect(Collectors.toList());

        return ResponseUtils.success(responseList);
    }
}
```

---

### 6. API 层 (`module-name-api/`)

**职责**: 对外暴露的接口定义和 DTO

**规范**:
- Service 接口：`@CloudService` 注解
- DTO/Model：实现 `Serializable`，使用 Lombok
- 命名：
  - 接口：`<Feature>Service.java`
  - 请求模型：`<Feature>Req.java` 或 `<Feature>Model.java`
  - 响应模型：`<Feature>Response.java`

**示例**:
```java
@CloudService
public interface WordService {
    RpcResultDTO<List<WordModelResponse>> matchByDesc(DescModel descModel);
}
```

---

## 分层调用关系图

```
┌─────────────────────────────────────────────────────────────┐
│  外部调用 (其他模块/前端)                                     │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  API 层 (@CloudService 接口定义)                               │
│  - WordService                                              │
│  - DTOs: DescModel, WordModelResponse                       │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  Service 层 (@CloudComponent)                                │
│  - WordServiceImpl                                          │
│  - 职责：RPC 包装、数据转换                                    │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  Manage 层 (@Component)                                      │
│  - WordManage extends ServiceImpl                           │
│  - 职责：单表业务逻辑、复杂查询                                │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  Mapper 层 (@Repository + @Mapper)                           │
│  - WordMapper extends BaseMapper                            │
│  - 职责：数据访问                                            │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  Entity 层                                                   │
│  - WordModel                                                │
│  - 职责：数据库表映射                                         │
└─────────────────────────────────────────────────────────────┘

注：Help 层用于跨多表业务协调，可同时注入多个 Manage
```

---

## Controller 层使用规范

**重要**：项目使用 JResCloud 框架的统一网关处理外部请求，普通业务功能**不需要** Controller 层。

### 何时不使用 Controller 层

**普通业务功能**（90% 的场景）：
- 模块间数据查询/操作
- 业务逻辑处理
- 数据增删改查

**正确做法**：使用 `@CloudService` + `@CloudComponent` 实现 RPC 服务

```java
// API 层：接口定义
@CloudService
public interface WordService {
    RpcResultDTO<List<WordModelResponse>> matchByDesc(DescModel descModel);
}

// Server 层：实现类
@CloudComponent
public class WordServiceImpl implements WordService {
    @Resource
    private WordManage wordManage;

    @Override
    public RpcResultDTO<List<WordModelResponse>> matchByDesc(DescModel descModel) {
        List<WordModel> wordModels = wordManage.matchByDesc(descModel.getDesc());
        // 数据转换...
        return ResponseUtils.success(responseList);
    }
}
```

### 何时使用 Controller 层

**特殊场景**（仅以下情况）：

1. **文件上传下载**：需要直接处理 HTTP 请求/响应流
2. **外部系统对接**：第三方系统直接调用的 HTTP 接口
3. **特定的 Web 页面**：需要返回视图或静态资源

**示例**：
```java
@RestController
@RequestMapping("/api/file")
public class FileController {

    @PostMapping("/upload")
    public ResponseEntity<UploadResponse> upload(
            @RequestParam("file") MultipartFile file) {
        // 文件上传逻辑
    }

    @GetMapping("/download/{fileId}")
    public ResponseEntity<Resource> download(@PathVariable String fileId) {
        // 获取文件
        File file = new File(filePath);
        InputStream inputStream = new FileInputStream(file);
        InputStreamResource resource = new InputStreamResource(inputStream);
        // 返回 ResponseEntity<Resource>
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"xxx\"")
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .body(resource);
    }
}
```

**注意**：HTTP 下载接口应返回 `ResponseEntity<Resource>`，不要使用 `IOUtils.copy` 直接操作响应流。

### 判断流程

```
需要开发新功能
       ↓
是否需要直接处理 HTTP 请求/响应？
       ↓
    是 → 使用 @RestController (文件上传下载、外部接口)
       ↓
    否 → 使用 @CloudService + @CloudComponent (普通业务功能)
```

### 架构说明

- **统一网关**：项目外部有 JResCloud 统一网关，所有外部请求通过网关路由
- **模块间通信**：模块间通过 JResCloud RPC 框架通信，使用 `@CloudService` 暴露服务
- **无需 Controller**：普通业务功能不需要 Controller 层，避免架构冗余

---

## Request/Response 类命名与设计规范

### 1. 命名规范

**统一使用 `Req` 后缀**（不使用 `Request`）：

| 类型 | 命名规范 | 示例 |
|------|----------|------|
| 请求类 | `<业务名>Req.java` | `SqlQueryReq.java`、`SqlHistoryReq.java` |
| 响应类 | `<业务名>Response.java` | `SqlQueryResponse.java`、`WordModelResponse.java` |
| 模型类 | `<业务名>Model.java` | `SqlHistoryModel.java`、`WordModel.java` |

**错误示例**（不要使用）：
- `SqlQueryRequest.java` ❌（应使用 `SqlQueryReq.java`）
- `UserLoginRequest.java` ❌（应使用 `UserLoginReq.java`）

### 2. Request 类设计规范

**必须继承 `QueryParam` 基类，且不重复定义父类已有字段**：

```java
package com.hundsun.isms6.pubmodu.api.sqlquery.model;

import com.hundsun.isms6.common.model.QueryParam;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.io.Serializable;

/**
 * SQL 查询请求参数
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class SqlQueryReq extends QueryParam implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 数据源 ID
     */
    private Long datasourceId;

    /**
     * SQL 内容
     */
    private String sqlContent;

    // 继承自 QueryParam 的字段（无需重复定义）：
    // - pageNum: 页码
    // - pageSize: 每页条数
    // - orderBy: 排序字段
    // - operatorCode: 操作人编码
    // - order: 排序方式
}
```

**QueryParam 基类包含的字段**：
- `pageNum` - 页码
- `pageSize` - 每页条数
- `orderBy` - 排序字段
- `order` - 排序方式
- `operatorCode` - 操作人编码
- `total` - 总数
- `isVerify` - 验证标识
- `approveType` - 审批类型
- `key` - 关键字

### 3. Response 类设计规范

**不包含 `success` 和 `errorMsg` 字段**（由 `RpcResultDTO` 统一处理）：

```java
package com.hundsun.isms6.pubmodu.api.sqlquery.model;

import lombok.Data;
import java.io.Serializable;
import java.util.List;
import java.util.Map;

/**
 * SQL 查询响应参数
 * 注：success 和 errorMsg 字段由 RpcResultDTO 统一处理，此处不需要
 */
@Data
public class SqlQueryResponse implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 数据列表
     */
    private List<Map<String, Object>> dataList;

    /**
     * 列名列表
     */
    private List<String> columns;

    /**
     * 返回行数
     */
    private int rowCount;

    /**
     * 执行耗时 (毫秒)
     */
    private int durationMs;
}
```

**错误示例**（不要包含）：
```java
// ❌ 不要这样写
@Data
public class SqlQueryResponse {
    private boolean success;      // 错误！由 RpcResultDTO 处理
    private String errorMsg;      // 错误！由 RpcResultDTO 处理
    private List<Map<String, Object>> dataList;  // 正确
}
```

### 4. Service 接口返回类型

**使用 `RpcResultDTO<T>` 包装**：

```java
@CloudService
public interface SqlQueryService {

    // 单个对象返回
    RpcResultDTO<SqlQueryResponse> executeQuery(SqlQueryReq request);

    // 分页返回（使用 PageInfo）
    RpcResultDTO<PageInfo<SqlHistoryModel>> listHistory(SqlHistoryReq request);

    // 列表返回
    RpcResultDTO<List<FundInfoModel>> listFunds(FundListReq request);
}
```

**参考示例**：
- `FundAlertCloseLineInfoService#listFundAlertCloseLineInfo` - 返回 `RpcResultDTO<PageInfo<FundAlertCloseLineInfoModel>>`

### 5. ServiceImpl 实现规范

**使用 `ResponseUtils.success()` 返回**：

```java
@CloudComponent
@Slf4j
public class SqlQueryServiceImpl implements SqlQueryService {

    @Resource
    private SqlQueryManage sqlQueryManage;

    @Override
    public RpcResultDTO<SqlQueryResponse> executeQuery(SqlQueryReq request) {
        SqlQueryResult result = sqlQueryManage.executeQuery(
            request.getDatasourceId(),
            request.getSqlContent(),
            request.getOperatorCode(),
            request.getOperatorName(),
            request.getClientIp()
        );

        SqlQueryResponse response = new SqlQueryResponse();
        BeanUtils.copyProperties(result, response);

        // 使用 ResponseUtils.success() 包装返回
        return ResponseUtils.success(response);
    }
}
```

**错误示例**（不要这样写）：
```java
// ❌ 不要手动设置 success 和 errorMsg
@Override
public RpcResultDTO<SqlQueryResponse> executeQuery(SqlQueryReq request) {
    SqlQueryResponse response = new SqlQueryResponse();
    response.setSuccess(true);        // 错误！不要手动设置
    response.setErrorMsg(null);       // 错误！不要手动设置
    return new RpcResultDTO<>(response);
}
```

### 6. 检查清单

代码完成前请确认：
- [ ] Request 类使用 `Req` 后缀（非 `Request`）
- [ ] Request 类继承 `QueryParam`
- [ ] Request 类使用 `@EqualsAndHashCode(callSuper = true)`
- [ ] Response 类不包含 `success` 字段
- [ ] Response 类不包含 `errorMsg` 字段
- [ ] Service 接口返回 `RpcResultDTO<T>`
- [ ] ServiceImpl 使用 `ResponseUtils.success()` 返回
- [ ] Entity String 字段添加 `typeHandler` 和 `jdbcType`
- [ ] HTTP 下载接口返回 `ResponseEntity<Resource>`

---

## Import 语句规范

**原则**：生成代码时默认使用 import 语句，不使用全限定类名。

- ✅ 使用：`import com.example.MyClass;` + `MyClass obj = new MyClass();`
- ❌ 禁用：`com.example.MyClass obj = new com.example.MyClass();`

**例外**：当出现类名重复时（如 `java.util.Date` 和 `java.sql.Date`），可使用全限定类名消除歧义。

---

## Bean 注入与异常处理规范

### 1. Bean 注入规范

| 场景 | 注解 | 示例 |
|------|------|------|
| 同模块 Bean 注入 | `@Autowired` | `TfGzbCheckSubjManage`、`TfGzbCodeMapManager` |
| 跨模块 RPC 调用 | `@CloudReference(group = "isms6", version = "v")` | `SecurityService` |
| 非 Bean 类获取 Bean | `SpringContextUtil.getBean()` | 仅用于特殊场景 |

**示例**：
```java
@CloudComponent
@Service
public class TfGzbCodeMapServiceImpl extends ServiceImpl<TfGzbCodeMapMapper, TfGzbCodeMap> implements TfGzbCodeMapService {

    // 同模块 Bean - 使用 @Autowired
    @Autowired
    private TfGzbCheckSubjManage tfGzbCheckSubjManage;

    @Autowired
    private TfGzbCodeMapManager tfGzbCodeMapManager;

    // 跨模块 RPC 调用 - 使用 @CloudReference
    @CloudReference(group = "isms6", version = "v")
    private SecurityService securityService;
}
```

### 2. 异常处理规范

**业务校验异常**：使用 `throw new BaseBizException("错误信息")`

```java
@Override
public RpcResultDTO<Integer> batchUpdateTargetInfo(TfGzbCodeMapUpdateReq req) {
    // 业务校验异常 - 使用 throw new BaseBizException()
    if (req.getFundId() == null || req.getFundId() <= 0) {
        throw new BaseBizException("产品ID不能为空");
    }
    // ...
}
```

**错误示例**：
```java
// ❌ 不要使用 RpcResultUtils.error() 返回业务校验错误
if (req.getFundId() == null) {
    return RpcResultUtils.error("产品ID不能为空");
}
```

---

## 历史代码重构规范 (模式 B → 模式 A)

### 问题描述

历史代码中存在**模式 B**（已过时）：
```java
// 模式 B - 不推荐
@CloudComponent
public class CondIndexInfoServiceImpl extends ServiceImpl<CondIndexInfoMapper, CondIndexInfo>
    implements CondIndexInfoService {

    @Autowired
    private CondIndexInfoManage condIndexInfoManage;

    // Service 层既继承 ServiceImpl 又注入 Manage，职责不清
}
```

### 目标模式

重构为**模式 A**（推荐）：
```java
// 模式 A - 推荐
@CloudComponent
public class CondIndexInfoServiceImpl implements CondIndexInfoService {

    @Resource
    private CondIndexInfoManage condIndexInfoManage;

    // Service 层只负责 RPC 暴露和数据转换
}
```

### 重构步骤

1. **Service 层改造**:
   - 移除 `extends ServiceImpl<Mapper, Entity>`
   - 保留 `@CloudComponent` 和接口实现
   - 业务逻辑委托给 Manage 层

2. **Manage 层强化**:
   - 确保继承 `ServiceImpl<Mapper, Entity>`
   - 将 Service 层中的业务逻辑移动到 Manage 层

3. **验证**:
   - 运行单元测试
   - 验证 RPC 接口功能正常

### 重构检查清单

- [ ] Service 层不再继承 ServiceImpl
- [ ] Service 层只包含数据转换和 RPC 包装
- [ ] 业务逻辑已移至 Manage 层
- [ ] Manage 层继承 ServiceImpl
- [ ] 所有测试通过

---

## 性能优化规范

### 禁止在循环体内进行数据库查询或 RPC 调用

**原则**：所有批量查询必须在循环体外执行，避免 N+1 查询问题。

**错误示例**（循环内查询）：
```java
// ❌ 错误：循环内进行 RPC 调用
for (Long fundId : fundIds) {
    FundInfoModel fundInfo = fundInfoModule.getFundInfoById(fundId);  // RPC 调用
    // ...
}
```

**正确示例**（批量查询）：
```java
// ✅ 正确：批量查询后在内存中处理
Map<String, Long> fundCode2FundIdMap = fundInfoModule.getFundCode2FundIdMap(fundCodes);
for (PlanFund planFund : planFundList) {
    Long fundId = fundCode2FundIdMap.get(planFund.getFundCode());
    // ...
}
```

### IN 子句超长处理

当 IN 子句中参数超过 1000 条时，应使用 `MontMybatisParameterUtils.inSql` 工具类处理，避免 SQL 异常。

**使用方式**：
```java
import com.hundsun.isms6.montmodu.util.MontMybatisParameterUtils;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;

// 正确使用 MontMybatisParameterUtils.inSql
QueryWrapper<PlanFund> queryWrapper = new QueryWrapper<>();
MontMybatisParameterUtils.inSql(queryWrapper, "fund_id", fundIds);
List<PlanFund> list = this.baseMapper.selectList(queryWrapper);
```

**`MontMybatisParameterUtils.inSql` 内部机制**：
- 参数 ≤ 3000：使用拼 SQL 方案，按 900 条一批拆分，用 `OR` 拼接
- 参数 > 3000：使用临时表方案

**注意**：该工具类仅支持 `QueryWrapper`，不支持 `LambdaQueryWrapper`。

### 批量操作检查清单

- [ ] 循环体内无数据库查询
- [ ] 循环体内无 RPC 调用
- [ ] 批量查询优先于逐条查询
- [ ] IN 子句超 1000 条时使用 `MontMybatisParameterUtils.inSql`

---

## 代码生成模板（根据表名快速生成）

当用户提供表名时，应按以下结构生成代码：

| 输入 | 输出 |
|------|------|
| 表名：`TM_Example` | 1. `ExampleModel.java` (entity/) |
| | 2. `ExampleMapper.java` (mapper/) + XML |
| | 3. `ExampleManage.java` (manage/) |
| | 4. `ExampleServiceImpl.java` (service/) |
| | 5. `ExampleService.java` (API 层) |
| | 6. `ExampleModelResponse.java` (API 层 DTO) |

**生成原则**:
- 先分析表结构生成 Entity
- 根据查询需求生成 Mapper 方法
- 根据业务需求生成 Manage 方法
- Service 层保持精简，仅暴露必要的 RPC 接口
