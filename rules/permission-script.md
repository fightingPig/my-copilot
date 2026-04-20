# 权限脚本生成规范

本文档定义 ISMS6 项目中菜单、接口权限初始化脚本的生成规则。

---

## 一、权限脚本结构概述

一个完整的权限初始化脚本包含以下 6 个部分，按顺序执行：

```sql
begin
    -- 1. 删除历史数据（幂等性处理）
    delete from tsys_menu where trans_code = 'xxx';
    delete from tsys_trans where trans_code = 'xxx';
    delete from tsys_subtrans where trans_code = 'xxx';
    delete from tsys_subtrans_relurl where trans_code = 'xxx';
    delete from tsys_role_right where trans_code = 'xxx' and role_code = 'admin';

    -- 2. 插入菜单信息
    INSERT INTO tsys_menu(...);

    -- 3. 插入功能权限
    INSERT INTO tsys_trans(...);

    -- 4. 插入按钮权限
    INSERT INTO tsys_subtrans(...);  -- 多个

    -- 5. 插入API URL权限
    INSERT INTO tsys_subtrans_relurl(...);  -- 多个

    -- 6. 分配权限到admin角色
    INSERT INTO tsys_role_right(...);  -- 多个
end;
commit;
```

---

## 二、各表字段说明

### 2.1 tsys_menu（菜单表）

| 字段 | 说明 | 示例 |
|------|------|------|
| menu_code | 菜单编码（唯一标识） | ruleBatchUpload |
| kind_code | 模块编码 | isms6 |
| trans_code | 关联功能编码 | ruleBatchUpload |
| sub_trans_code | 子功能编码 | ruleBatchUpload |
| menu_name | 菜单名称（中文） | 规则批量导入 |
| menu_arg | 菜单参数 | '' |
| menu_icon | 菜单图标 | '' |
| menu_url | 菜单URL | /isms6-montmodu/ruleBatchUpload/ruleBatchUpload |
| window_type | 窗口类型 | NULL |
| window_model | 窗口模式 | NULL |
| tip | 提示 | NULL |
| hot_key | 快捷键 | NULL |
| parent_code | 父菜单编码 | monitorRuleShortcut |
| order_no | 排序号 | 15 |
| open_flag | 打开标志 | NULL |
| tree_idx | 树索引 | #bizroot#isms6#monitorSet#monitorRuleShortcut#ruleBatchUpload# |
| remark | 备注 | '' |
| menu_plugin_name | 插件名称 | '' |
| menu_plugin_dll | 插件DLL | '' |
| menu_type | 菜单类型 | hui |
| help_url | 帮助URL | NULL |
| tenant_id | 租户ID | '' |
| module_id | 模块ID | 0 |
| menu_no | 菜单编号 | NULL |
| menu_level | 菜单层级 | 0 |
| menu_i18n | 国际化 | NULL |
| ext_field | 扩展字段 | NULL |
| ext_field1~5 | 扩展字段1-5 | NULL |
| menu_is_leaf | 是否叶子节点 | 1 |
| module_type | 模块类型 | isms6-montmodu |
| param | 参数 | '0' |
| app_code | 应用编码 | isms6-montmodu |
| is_hidden | 是否隐藏 | '1' |
| is_keep_alivea | 是否保持活跃 | '1' |
| lang_menu_name | 英文菜单名 | '' |
| hk_menu_name | 港繁菜单名 | '' |
| font_name | 字体名 | '' |
| sub_system_no | 子系统编号 | NULL |
| org_id | 机构ID | NULL |
| menu_class | 菜单类 | NULL |

### 2.2 tsys_trans（功能权限表）

| 字段 | 说明 | 示例 |
|------|------|------|
| trans_code | 功能编码 | ruleBatchUpload |
| trans_name | 功能名称（中文） | 规则批量导入 |
| kind_code | 模块编码 | isms6 |
| model_code | 模型编码 | 1 |
| remark | 备注 | NULL |
| ext_field_1~3 | 扩展字段 | NULL |
| tenant_id | 租户ID | NULL |
| trans_order | 排序 | NULL |
| parent_code | 父功能编码 | NULL |
| tree_idx | 树索引 | NULL |

### 2.3 tsys_subtrans（按钮权限表）

| 字段 | 说明 | 示例 |
|------|------|------|
| trans_code | 功能编码 | ruleBatchUpload |
| sub_trans_code | 子功能编码（按钮编码） | import |
| sub_trans_name | 子功能名称（按钮中文名） | 导入接口 |
| rel_serv | 关联服务 | NULL |
| rel_url | 关联URL | '' |
| ctrl_flag | 控制标志 | 1 |
| login_flag | 登录标志 | '' 或 '1' |
| remark | 备注 | '' |
| ext_field_1~3 | 扩展字段 | NULL |
| tenant_id | 租户ID | NULL |
| sub_trans_arg | 子功能参数 | '' |
| module_type | 模块类型 | NULL |
| subtrans_order | 排序号 | 4 |

**ctrl_flag 说明**：
- `1`：可见可用
- `0` 或其他：不可见

**login_flag 说明**：
- `'1'`：需要登录
- `''`：不需要登录

### 2.4 tsys_subtrans_relurl（API URL权限表）

| 字段 | 说明 | 示例 |
|------|------|------|
| url | API路径 | /isms6/isms6-montmodu-server/v/importRuleBatch |
| url_name | URL名称 | ruleBatchUpload#import |
| trans_code | 功能编码 | ruleBatchUpload |
| sub_trans_code | 子功能编码 | import |
| url_param | URL参数 | NULL |
| remark | 备注 | 导入接口 |

**url_name 格式**：`{trans_code}#{sub_trans_code}`

### 2.5 tsys_role_right（角色权限表）

| 字段 | 说明 | 示例 |
|------|------|------|
| trans_code | 功能编码 | ruleBatchUpload |
| sub_trans_code | 子功能编码 | import |
| role_code | 角色编码 | admin |
| create_by | 创建人 | NULL 或 'admin' |
| create_date | 创建日期 | 0 |
| begin_date | 开始日期 | 0 |
| end_date | 结束日期 | 0 |
| right_flag | 权限标志 | '1' 或 '2' |
| right_enable | 权限启用 | NULL |
| module_type | 模块类型 | NULL |
| action_type | 动作类型 | NULL |
| tenant_uuid | 租户UUID | 'BIZUUID' |
| tenant_id | 租户ID | NULL |
| kind_code | 模块编码 | NULL |

**right_flag 说明**（每个子功能需要插入两条）：
- `'1'`：操作权限
- `'2'`：授权权限

---

## 三、变量占位符说明

生成脚本时，需要替换以下占位符：

| 占位符 | 说明 | 示例 |
|--------|------|------|
| ${trans_code} | 功能/菜单编码（小写驼峰） | ruleBatchUpload |
| ${menu_name} | 菜单名称（中文） | 规则批量导入 |
| ${parent_code} | 父菜单编码 | monitorRuleShortcut |
| ${order_no} | 排序号 | 15 |
| ${module_type} | 模块类型 | isms6-montmodu |
| ${server_name} | 服务名称 | isms6-montmodu-server |
| ${api_base_path} | API基础路径 | /isms6/isms6-montmodu-server/v |
| ${sub_trans_items} | 子功能列表（见下文） | 见下文 |

---

## 四、子功能项定义

每个功能模块包含多个子功能（按钮/API），每个子功能需要定义：

```properties
# 格式：sub_trans_code|sub_trans_name|subtrans_order|ctrl_flag|login_flag|rel_url

# 示例：
import|导入接口|4|1||/isms6/isms6-montmodu-server/v/importRuleBatch
listFileInfo|文件信息查询列表|3|1||
listDetailInfo|明细查询列表|2|1||
getDetailInfo|明细查询单条|5|1||
updateStatusDetailInfo|修改明细状态|6|1|admin|
```

| 子功能项 | 说明 | 示例 |
|----------|------|------|
| sub_trans_code | 子功能编码 | import |
| sub_trans_name | 子功能名称 | 导入接口 |
| subtrans_order | 排序号 | 4 |
| ctrl_flag | 控制标志 | 1 |
| login_flag | 登录标志 | '' 或 '1' |
| rel_url | API URL（可选） | /v/importRuleBatch |

**登录标志规则**：
- 页面主入口（第一个sub_trans）：`login_flag = '1'`
- 其他按钮/接口：`login_flag = ''`

---

## 五、文件命名规范

```
{当前日期YYYYMMDD}_DML_TsysMenu_{trans_code}_v{序号}.sql
```

**示例**：
```
20260327_DML_TsysMenu_ruleBatchUpload_v01.sql
```

**说明**：
- `{当前日期YYYYMMDD}` 为脚本创建当天的日期，如 2026年3月27日 → `20260327`

---

## 六、生成模板

### 6.1 完整SQL模板

```sql
begin
    -- 删除历史数据
    delete from tsys_menu where trans_code = '${trans_code}';
    delete from tsys_trans where trans_code = '${trans_code}';
    delete from tsys_subtrans where trans_code = '${trans_code}';
    delete from tsys_subtrans_relurl where trans_code = '${trans_code}';
    delete from tsys_role_right where trans_code = '${trans_code}' and role_code = 'admin';

    -- 菜单
    INSERT INTO tsys_menu(menu_code, kind_code, trans_code, sub_trans_code, menu_name, menu_arg, menu_icon, menu_url, window_type, window_model, tip, hot_key, parent_code, order_no, open_flag, tree_idx, remark, menu_plugin_name, menu_plugin_dll, menu_type, help_url, tenant_id, module_id, menu_no, menu_level, menu_i18n, ext_field, ext_field1, ext_field2, ext_field3, ext_field4, ext_field5, menu_is_leaf, module_type, param, app_code, is_hidden, is_keep_alivea, lang_menu_name, hk_menu_name, font_name, sub_system_no, org_id, menu_class)
    VALUES ('${trans_code}', 'isms6', '${trans_code}', '${trans_code}', '${menu_name}', '', '', '/${module_type}/${trans_code}/${trans_code}', NULL, NULL, NULL, NULL, '${parent_code}', ${order_no}, NULL, '#bizroot#isms6#monitorSet#${parent_code}#${trans_code}#', '', '', '', 'hui', NULL, '', 0, NULL, 0, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '${module_type}', '0', '1', '', '', '', NULL, NULL, NULL);

    -- 功能权限
    INSERT INTO tsys_trans(trans_code, trans_name, kind_code, model_code, remark, ext_field_1, ext_field_2, ext_field_3, tenant_id, trans_order, parent_code, tree_idx)
    VALUES ('${trans_code}', '${menu_name}', 'isms6', '1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

${sub_trans_statements}

${api_url_statements}

${role_right_statements}

end;
commit;
```

### 6.2 子功能语句块（tsys_subtrans）

```sql
    -- 按钮权限
    INSERT INTO tsys_subtrans(trans_code, sub_trans_code, sub_trans_name, rel_serv, rel_url, ctrl_flag, login_flag, remark, ext_field_1, ext_field_2, ext_field_3, tenant_id, sub_trans_arg, module_type, subtrans_order)
    VALUES ('${trans_code}', '${sub_trans_code}', '${sub_trans_name}', NULL, '', '1', '${login_flag}', '', NULL, NULL, NULL, NULL, '', NULL, ${subtrans_order});
```

**注意**：
- 第一个子功能（页面入口）需要设置 `login_flag = '1'`
- 其他子功能设置 `login_flag = ''`
- 有具体URL的子功能需要填充 `rel_url` 字段

### 6.3 API URL语句块（tsys_subtrans_relurl）

```sql
    -- Api权限
    INSERT INTO tsys_subtrans_relurl(url, url_name, trans_code, sub_trans_code, url_param, remark)
    VALUES ('${api_base_path}/${api_url}', '${trans_code}#${sub_trans_code}', '${trans_code}', '${sub_trans_code}', NULL, '${sub_trans_name}');
```

**说明**：
- 仅当子功能有实际API接口时才插入此记录
- URL格式：`${api_base_path}/${api_url}`
- url_name格式：`${trans_code}#${sub_trans_code}`

### 6.4 角色权限语句块（tsys_role_right）

```sql
    -- 分配权限到admin
    INSERT INTO tsys_role_right(trans_code, sub_trans_code, role_code, create_by, create_date, begin_date, end_date, right_flag, right_enable, module_type, action_type, tenant_uuid, tenant_id, kind_code)
    VALUES ('${trans_code}', '${sub_trans_code}', 'admin', NULL, 0, 0, 0, '1', NULL, NULL, NULL, 'BIZUUID', NULL, NULL);
    INSERT INTO tsys_role_right(trans_code, sub_trans_code, role_code, create_by, create_date, begin_date, end_date, right_flag, right_enable, module_type, action_type, tenant_uuid, tenant_id, kind_code)
    VALUES ('${trans_code}', '${sub_trans_code}', 'admin', NULL, 0, 0, 0, '2', NULL, NULL, NULL, 'BIZUUID', NULL, NULL);
```

**注意**：
- 每个子功能需要插入 2 条记录（right_flag = '1' 和 '2'）
- create_by 字段：第一个子功能用 NULL，其他用 'admin'

---

## 七、生成示例

### 输入信息

| 参数 | 值 |
|------|-----|
| trans_code | ruleBatchUpload |
| menu_name | 规则批量导入 |
| parent_code | monitorRuleShortcut |
| order_no | 15 |
| module_type | isms6-montmodu |
| api_base_path | /isms6/isms6-montmodu-server/v |

| 子功能 | 名称 | 排序 | 登录标志 | API URL |
|--------|------|------|----------|---------|
| import | 导入接口 | 4 | '' | /importRuleBatch |
| listFileInfo | 文件信息查询列表 | 3 | '' | /queryRuleRecordInfoList |
| listDetailInfo | 明细查询列表 | 2 | '' | /queryRuleRecordDetailList |
| getDetailInfo | 明细查询单条 | 5 | '' | /getRuleRecordDetailInfo |
| updateStatusDetailInfo | 修改明细状态 | 6 | admin | /updateRuleRecordDetailInfo |
| ruleBatchUpload | 规则批量导入（主入口） | NULL | '1' | /ruleBatchUpload/ruleBatchUpload |

### 输出文件

`20230515_DML_TsysMenu_ruleBatchUpload_v01.sql`（即用户提供的参考文件）

---

## 八、检查清单

生成权限脚本后，请确认：

- [ ] 已删除历史数据（5张表）
- [ ] 菜单名称正确
- [ ] 父菜单编码正确
- [ ] 排序号合理
- [ ] 所有子功能已定义
- [ ] 第一个子功能 login_flag = '1'
- [ ] 有API的子功能已插入 tsys_subtrans_relurl
- [ ] 所有子功能已分配 admin 权限（各2条）
- [ ] 文件名符合规范

---

## 九、版本号确定

**版本号从模块的 `pom.xml` 文件中获取**：

```bash
grep "<version>" {module-name-server}/pom.xml | head -2
# 例如：<version>202601.00.003M2-SNAPSHOT</version>
```

- 提取 `<version>` 值，**只去掉 `-SNAPSHOT` 后缀**
- 例如：`202601.00.003M2-SNAPSHOT` → `202601.00.003M2`
- **注意**：不要进一步处理版本号的其他部分（如 `M2` 等后缀必须保留）

---

## 十、DML文件存放路径

```
{module-name-server}/deploy/sqls/{database-type}/bizframe/{version}/
```

| 数据库类型 | 路径 |
|------------|------|
| Oracle | oracle/bizframe/{version}/ |
| Dameng | dm/bizframe/{version}/ |
| OceanBase | oboracle/bizframe/{version}/ |
| GaussDB | gaussdbopengauss/bizframe/{version}/ |

**说明**：
- 权限脚本放在 `bizframe` 目录（非 `default` 目录）
- **版本号从 pom.xml 获取**（只去掉 `-SNAPSHOT` 后缀，如 `202601.00.003M2-SNAPSHOT` → `202601.00.003M2`）
- 需要为 4 种数据库类型都创建脚本
- dm 数据库脚本使用 GBK 编码，其他使用 UTF-8 编码

---

## 十二、重要规则：新增接口必须配套权限脚本

**规则**：凡是代码涉及到新增接口（RPC 或 HTTP），必须同时创建对应的权限脚本。

### 1. 必须配套创建的内容

| 接口类型 | 权限脚本要求 |
|---------|-------------|
| RPC 接口 | 完整权限脚本（菜单+功能+按钮+API URL） |
| HTTP 接口 | 增量权限脚本（按钮+API URL） |

### 2. 必填确认项

在创建权限脚本前，必须确认以下信息：

| 确认项 | 说明 |
|--------|------|
| **parent_code** | 父菜单编码，必须咨询用户确认 |

### 3. 校验检查清单

每次新增接口时，检查是否遗漏权限脚本：

- [ ] RPC 接口已创建完整权限脚本？
- [ ] HTTP 接口已创建增量权限脚本？
- [ ] parent_code 已咨询用户确认？
- [ ] ctrl_flag 值已咨询用户确认？
- [ ] 权限脚本已为 4 种数据库类型创建？

---

## 十一、HTTP 接口权限脚本

HTTP 接口（Controller）权限脚本与 RPC 接口不同，属于**增量脚本**。

### 1. 脚本类型区分

| 类型 | 使用场景 | 涉及表 |
|------|---------|--------|
| **完整脚本** | RPC 接口，新建菜单+功能+按钮+API URL | 5 张表全部操作 |
| **增量脚本** | HTTP 接口，只需添加子功能到已有菜单 | 3 张表（subtrans、subtrans_relurl、role_right） |

### 2. HTTP 接口 URL 规则

**格式**：`{类上 RequestMapping}/{方法上 GetMapping/PostMapping}`

示例：
- 类 `@RequestMapping("/v")` + 方法 `@GetMapping("/downloadLogFile")` → URL = `/v/downloadLogFile`
- 类 `@RequestMapping("/common")` + 方法 `@PostMapping("/downloadFile")` → URL = `/common/downloadFile`

### 3. HTTP 接口脚本模板

```sql
begin
    -- 删除历史数据（只涉及子功能相关表）
    delete from tsys_subtrans where trans_code = '${trans_code}' and sub_trans_code in ('${sub_trans_code}');
    delete from tsys_subtrans_relurl where trans_code = '${trans_code}' and sub_trans_code in ('${sub_trans_code}');
    delete from tsys_role_right where trans_code = '${trans_code}' and sub_trans_code in ('${sub_trans_code}') and role_code = 'admin';

    -- 按钮权限
    INSERT INTO tsys_subtrans(trans_code, sub_trans_code, sub_trans_name, rel_serv, rel_url, ctrl_flag, login_flag, remark, ext_field_1, ext_field_2, ext_field_3, tenant_id, sub_trans_arg, module_type, subtrans_order)
    VALUES ('${trans_code}', '${sub_trans_code}', '${sub_trans_name}', NULL, '', '${ctrl_flag}', '${login_flag}', '', NULL, NULL, NULL, NULL, '', NULL, ${subtrans_order});

    -- Api权限
    INSERT INTO tsys_subtrans_relurl(url, url_name, trans_code, sub_trans_code, url_param, remark)
    VALUES ('${url}', '${trans_code}#${sub_trans_code}', '${trans_code}', '${sub_trans_code}', NULL, '${sub_trans_name}');

    -- 分配权限到admin
    INSERT INTO tsys_role_right(trans_code, sub_trans_code, role_code, create_by, create_date, begin_date, end_date, right_flag, right_enable, module_type, action_type, tenant_uuid, tenant_id, kind_code)
    VALUES ('${trans_code}', '${sub_trans_code}', 'admin', 'admin', 0, 0, 0, '1', NULL, NULL, NULL, 'BIZUUID', NULL, NULL);
    INSERT INTO tsys_role_right(trans_code, sub_trans_code, role_code, create_by, create_date, begin_date, end_date, right_flag, right_enable, module_type, action_type, tenant_uuid, tenant_id, kind_code)
    VALUES ('${trans_code}', '${sub_trans_code}', 'admin', 'admin', 0, 0, 0, '2', NULL, NULL, NULL, 'BIZUUID', NULL, NULL);
end;
commit;
```

### 4. ctrl_flag 字段规则

| 值 | 含义 | 使用场景 |
|-----|------|---------|
| `'0'` | 不可见/不可用 | 上下游系统直接调用的接口 |
| `'1'` | 可见可用 | 本系统前台调用的接口 |

**重要**：HTTP 接口必须咨询用户确认 ctrl_flag 值。

### 5. rel_url 字段

HTTP 接口的 `rel_url` 字段固定为空字符串 `''`。

### 6. HTTP vs RPC 接口权限脚本差异

| 差异项 | HTTP 接口（增量脚本） | RPC 接口（完整脚本） |
|--------|---------------------|---------------------|
| **脚本类型** | 增量脚本 | 完整脚本 |
| **涉及表** | tsys_subtrans、tsys_subtrans_relurl、tsys_role_right | 5 张表全部 |
| **tsys_menu** | ❌ 不操作 | ✅ 需要插入 |
| **tsys_trans** | ❌ 不操作 | ✅ 需要插入 |
| **API URL 格式** | `/v/downloadLogFile` | `/isms6/isms6-montmodu-server/v/queryPlanFund` |
| **rel_url** | 固定为空 `''` | 页面主入口有值，其他为空 |
| **login_flag** | 通常 `'0'` | 页面主入口 `'1'`，其他 `''` |
| **ctrl_flag** | `'0'`=上下游，`'1'`=本系统前台 | `'1'` |

### 7. HTTP 接口脚本示例

**场景**：为已有菜单 `emailManage` 添加下载子功能

```sql
begin
    delete from tsys_subtrans where trans_code = 'emailManage' and sub_trans_code in ('downloadFile');
    delete from tsys_subtrans_relurl where trans_code = 'emailManage' and sub_trans_code in ('downloadFile');
    delete from tsys_role_right where trans_code = 'emailManage' and sub_trans_code in ('downloadFile') and role_code='admin';

    -- 按钮权限（ctrl_flag=1 表示本系统前台调用）
    INSERT INTO tsys_subtrans(trans_code, sub_trans_code, sub_trans_name, rel_serv, rel_url, ctrl_flag, login_flag, remark, ext_field_1, ext_field_2, ext_field_3, tenant_id, sub_trans_arg, module_type, subtrans_order)
    VALUES ('emailManage', 'downloadFile', '附件下载', NULL, '', '1', '', '', NULL, NULL, NULL, NULL, '', NULL, 17);

    -- Api权限
    INSERT INTO tsys_subtrans_relurl(url, url_name, trans_code, sub_trans_code, url_param, remark)
    VALUES ('/common/downloadFile', 'emailManage#downloadFile', 'emailManage', 'downloadFile', NULL, '附件下载');

    -- 分配权限到admin
    INSERT INTO tsys_role_right(trans_code, sub_trans_code, role_code, create_by, create_date, begin_date, end_date, right_flag, right_enable, module_type, action_type, tenant_uuid, tenant_id, kind_code)
    VALUES ('emailManage', 'downloadFile', 'admin', 'admin', 0, 0, 0, '1', NULL, NULL, NULL, 'BIZUUID', NULL, NULL);
    INSERT INTO tsys_role_right(trans_code, sub_trans_code, role_code, create_by, create_date, begin_date, end_date, right_flag, right_enable, module_type, action_type, tenant_uuid, tenant_id, kind_code)
    VALUES ('emailManage', 'downloadFile', 'admin', 'admin', 0, 0, 0, '2', NULL, NULL, NULL, 'BIZUUID', NULL, NULL);
end;
commit;
```
