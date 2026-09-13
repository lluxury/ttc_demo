To achieve this in Alibaba Cloud Resource Access Management (RAM), the recommended strategy is to combine **Alibaba Cloud's built-in global read-only policy** with a **tailored custom policy for ECS Cloud Assistant (云助手)**. 

Running scripts via the Alibaba Cloud CLI without logging into the OS (no SSH/RDP/VNC) is handled through **ECS Cloud Assistant** APIs (`RunCommand` / `InvokeCommand`).

---

### Recommended IAM / RAM Policy Setup

Attach the following **two policies** to the RAM User or RAM Role:

---

### 1. Global Read-Only Access (System Policy)
Attach the built-in system policy:
* **Policy Name:** `ReadOnlyAccess`
* **Coverage:** Grants read-only permissions across all Alibaba Cloud resources (ECS, RDS, OSS, VPC, SLB, etc.) without allowing modifications or resource creation.

---

### 2. Cloud Assistant Execution Policy (Custom Policy)
Since `ReadOnlyAccess` does not allow invoking commands, create a custom RAM policy that grants the ability to run scripts via Cloud Assistant and fetch their outputs.

#### **Custom Policy JSON:**
```json
{
  "Version": "1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:RunCommand",
        "ecs:InvokeCommand",
        "ecs:DescribeInvocations",
        "ecs:DescribeInvocationResults",
        "ecs:DescribeCommands",
        "ecs:StopInvocation"
      ],
      "Resource": [
        "acs:ecs:*:*:instance/*",
        "acs:ecs:*:*:command/*"
      ]
    }
  ]
}
```

---

### 3. Security Hardening & Best Practices (Least Privilege)

If you want to restrict this access further:

#### A. Restrict OS Execution User
By default, Cloud Assistant runs as `root` (Linux) or `system` (Windows). To enforce executing commands only as a low-privileged read-only OS user (e.g., `audituser` or `readonly`), add a condition block:
```json
"Condition": {
  "StringEquals": {
    "ecs:CommandRunAs": [
      "audituser"
    ]
  }
}
```

#### B. Restrict to Specific Instances or Resource Groups
Instead of `"acs:ecs:*:*:instance/*"`, limit permissions to specific instance IDs:
```json
"Resource": [
  "acs:ecs:cn-hangzhou:123456789012****:instance/i-bp1xxxxxxxxxxxx",
  "acs:ecs:cn-hangzhou:123456789012****:command/*"
]
```

---

### 4. How to Execute Query Scripts via Alibaba Cloud CLI

Once the policies are attached, you can execute commands and query outputs without logging in via SSH:

#### Step 1: Run a query command on the ECS instance
```bash
aliyun ecs RunCommand \
  --RegionId "cn-hangzhou" \
  --Type "RunShellScript" \
  --InstanceId.1 "i-bp1xxxxxxxxxxxx" \
  --CommandContent "df -h && free -m" \
  --Timeout 60
```
*Note: The CLI returns an `InvokeId` and `CommandId`.*

#### Step 2: Fetch the query execution results
```bash
aliyun ecs DescribeInvocationResults \
  --RegionId "cn-hangzhou" \
  --InstanceId "i-bp1xxxxxxxxxxxx" \
  --InvokeId "t-hzxxxxxxxxxxxx" \
  --ContentEncoding "PlainText"
```

---

### Summary Checklist

| Requirement | Implementation |
| :--- | :--- |
| **Global Read-Only** | Attach system policy `ReadOnlyAccess`. |
| **Access/View VMs** | Covered by `ReadOnlyAccess` (`ecs:Describe*`). |
| **Run Query Scripts (No OS login)** | Cloud Assistant APIs (`ecs:RunCommand`, `ecs:DescribeInvocationResults`). |
| **CLI Execution** | Create programmatic AccessKey (or assume STS RAM Role) for the RAM User. |





# money

**Azure AD B2C (Azure Active Directory Business to Consumer)**
使用 WeChat 帐户设置注册和登录

App Governance  付费



在拥有**账单权限**和**只读权限（ReadOnly）**的情况下，梳理阿里云环境并找出所有产生成本的服务，最权威、最高效的切入点是**“以账单为唯一真实源（Single Source of Truth），反向映射控制台资产”**。

以下是系统化的梳理方法与实操步骤：

---

### 第一步：从【费用与成本】抓取全量“收费源”（账单级梳理）

无论资源分布在哪个冷门地域（Region）、属于哪个子产品，只要产生费用，账单一定有记录。

#### 1. 导出「明细账单」（最全底表）
1. 登录阿里云控制台，右上角进入 **【费用与成本】** -> **【账单管理】** -> **【账单明细】**。
2. 建议拉取 **最近 1~3 个月** 的账单（防止遗漏按月扣费或周期性运行的服务）：
   - 选择 **“明细”** 或 **“计费项明细”**（CSV格式下载）。
3. **重点清洗和提取以下字段**：
   - `产品代码 / 产品名称`（如：云服务器ECS、日志服务SLS、对象存储OSS、NAT网关等）
   - `计费项`（如：云盘容量、公网流量、实例规格、索引流量）
   - `计费方式`（预付费/包年包月、后付费/按量付费）
   - `地域（Region）`
   - `实例ID / 资源ID`（关键：这是你后续找对应资源的凭证）
   - `应付金额 / 原价`

#### 2. 使用「成本分析」生成宏观视图
1. 进入 **【费用与成本】** -> **【成本分析】**。
2. 维度切换：
   - **按产品分类汇总**：直接拉出 Top 20 消费服务清单（计算、网络、存储、数据库等）。
   - **按地域汇总**：确认资产主要分布在哪些 Region，避免后续漏查冷门 Region。

---

### 第二步：利用只读权限验证并定位存量资产（资产级映射）

拿到明细账单中的 `产品`、`地域`、`实例ID` 后，利用只读权限进行核对与补全。

#### 1. 善用「资源管理（Resource Management）」与「资源目录」
不要一个个控制台点开看，阿里云提供了全局搜索工具：
* **资源列表 / 资源管理服务**（Resource Center）：
  * 进入 **【资源管理】** -> **【资源目录 / 资源组】** 或 **【资源管理 -> 资源列表】**。
  * 可以在这里跨地域（All Regions）直接搜索账单里的 `实例ID` 或按产品批量查看存量资产。
* **配置审计（Cloud Config，若已开通）**：
  * 只读查看所有被纳管资源的配置快照，能直接导出全量资产清单。

#### 2. 重点排查“易漏/隐性计费项”（隐形刺客）
通过账单+控制台，重点核查以下极易被遗忘但持续扣费的资源：

| 类别 | 易漏扣费资源 | 排查要点 |
| :--- | :--- | :--- |
| **网络** | **未绑定的 EIP** | EIP 绑定实例时不收实例费，**一旦闲置解绑反而会按小时收实例保留费**。 |
| | **NAT 网关 & 共享带宽** | 即使没有流量，NAT网关也有基础实例保有费。 |
| | **CLB / ALB (负载均衡)** | 即使无流量，按量付费的 ALB/CLB 也会收取按小时的实例费/LCU 费。 |
| | **CEN (云企业网)** | 跨地域互通的带宽包（Bandwidth Package）。 |
| **存储** | **未挂载的云盘 / 系统快照** | ECS 释放后随之保留的独立数据盘；历史保留的大量 ECS 自动快照。 |
| | **OSS 存储与 API** | OSS 不仅收存储费，还收 **Put/Get 请求次数费** 和 **外网流出流量费**。 |
| | **NAS 文件系统** | 闲置挂载点或未清理的数据。 |
| **中间件与安全** | **SLS 日志服务** | 开启了全量索引、Logtail 持续采集产生的写入流量费与索引费。 |
| | **DTS 数据同步** | 暂停或闲置的按量同步实例。 |
| | **云安全中心 / WAF** | 按资产授权数、防护带宽扣费的配置。 |

---

### 第三步：使用命令行/脚本加速梳理（可选）

如果你有 API/CLI 的只读权限（`AliyunBSSFullAccess` / `AliyunBSSReadOnlyAccess`），可以用 Python 脚本或 `aliyun-cli` 批量导出：

1. **调用 BSS OpenAPI** 查询实例账单明细：
   * 接口：`QueryInstanceBill` 或 `DescribeSplitItemBillDetails`
2. **结合 ResourceCenter API**：
   * 接口：`SearchResources`（全局跨产品跨 Region 查询所有资源列表，并与账单 ID 做 Join 关联）。

---

### 第四步：输出《云资产与费用拓扑矩阵》

整理后的终道产物建议归档为如下表格，方便向团队或管理层汇报及后续做成本优化（FinOps）：

| 序号 | 产品类别 | 阿里云产品 | 实例ID / 资源名称 | 地域 (Region) | 计费方式 | 月均费用 (元) | 费用占比 | 关联业务/用途 (待认领) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | 计算 | ECS (8C16G) | i-bp1xxxxxx | cn-hangzhou | 包年包月 | ¥800 | 25% | 核心应用后端 |
| 2 | 网络 | EIP (未绑定) | eip-bp1xxxxxx | cn-shanghai | 按量付费 | ¥150 | 4.6% | **疑似闲置/待释放** |
| 3 | 存储 | ECS快照 | s-bp1xxxxxx | cn-hangzhou | 按量付费 | ¥320 | 10% | 历史备份/待缩容 |
| 4 | 存储 | OSS Bucket | bucket-name | 全局 | 按量+存储包 | ¥200 | 6.2% | 静态资源存储 |
| 5 | 网络 | ALB (应用型负载均衡) | alb-xxxxxx | cn-hangzhou | 按量付费 | ¥450 | 14% | 网关入口 |

---

### 总结行动路线
1. **导出近 3 个月计费项明细（以账单做全集基准）**。
2. **按产品聚合（找出主力支出与隐形扣费项）**。
3. **利用资源管理/全局搜索（将账单实例 ID 还原到拓扑架构中）**。
4. **标记无业务归属的闲置收费资源（为后续降本做准备）**。



Gemini 3.7 Flash
Ran for 13s
面对**“手头资源列表静态滞后、但拥有阿里云只读（ReadOnlyAccess）和财务账单权限”的场景，“从账单出发（Top-Down 资金驱动）反推资产”**是业界公认最快、最全、最不会遗漏隐藏资源（如按量计费的快照、按量EIP、OSS冷存储、NAT网关流量、Logtail日志库等）的盘点方法。
以下是标准实战梳理方法论、操作步骤与可以直接执行的自动化脚本：

【步骤 1: 账单中心拉取明细】 ──> 【步骤 2: 聚合去重与过滤】 ──> 【步骤 3: 提取唯一资源ID】 ──> 【步骤 4: 只读权限逆向校验】 ──> 【步骤 5: 输出拓扑资产清单】
   (获取近 1~3 个月计费账单)       (过滤免费项/0元项，按服务分类)     (InstanceId / ResourceId)       (CLI/API 查询规格、状态与关联)    (形成持续更新的 CMDB 表格)

二、 具体操作路径（控制台快速摸底）
如果您想在 5 分钟内快速获取全局概览：
登录阿里云控制台 ➔ 进入 【费用与成本】(Billing Management)。
进入账单明细：
路径：费用与成本 ➔ 账单管理 ➔ 账单明细 (Billing Details)。
统计周期：建议选择 过去 1~3 个月（因为有些服务是按月出账，有些是按量按天结算，看 3 个月能防止遗漏周期性计费项）。
切换查看维度为【计费项明细】(Billing Item Details)：
统计项选择：计费项明细。
过滤条件：应付金额 > 0 或 现金支付 + 优惠券 > 0（排除未产生费用的免费额度）。
一键导出 CSV：
点击右上角 【导出账单明细】，选择全量字段（包含：产品代码 ProductCode、产品名称 ProductName、地域 Region、资源实例 ID (InstanceID)、资源组、计费方式、用量、应付金额）。


三、 自动化脚本：利用只读与账单权限全量拉取
利用阿里云 CLI 或 Python SDK（aliyun-python-sdk-bssopenapi / 现代 alibabacloud_bssopenapi20171214），可以自动化导出所有计费服务及关联实例。
1. Python 提取所有计费服务与实例清单（纯只读）

~~~python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
依赖安装: pip install alibabacloud_bssopenapi20171214 pandas
所需权限: AliyunBSSReadOnlyAccess (只读账单权限)
"""

import os
import json
import pandas as pd
from alibabacloud_bssopenapi20171214.client import Client as BssClient
from alibabacloud_bssopenapi20171214 import models as bss_models
from alibabacloud_tea_openapi import models as open_api_models
from alibabacloud_tea_util import models as util_models

# 1. 初始化客户端 (配置您的只读 AK/SK)
config = open_api_models.Config(
    access_key_id=os.environ.get("ALIBABA_CLOUD_ACCESS_KEY_ID"),
    access_key_secret=os.environ.get("ALIBABA_CLOUD_ACCESS_KEY_SECRET"),
    endpoint="business.aliyuncs.com"
)
client = BssClient(config)

def get_billing_services(billing_cycle="2026-07"):
    """拉取指定月份所有产生费用的产品与实例"""
    print(f"[*] 正在拉取 {billing_cycle} 账单明细...")
    
    all_records = []
    next_token = None
    max_results = 300
    
    while True:
        request = bss_models.DescribeInstanceBillRequest(
            billing_cycle=billing_cycle,
            is_billing_item=True, # 细化到计费项
            max_results=max_results,
            next_token=next_token
        )
        runtime = util_models.RuntimeOptions()
        response = client.describe_instance_bill_with_options(request, runtime)
        
        items = response.body.data.items
        for item in items:
            # 仅保留实际产生费用的记录 (应付金额 > 0)
            if item.pretax_amount and float(item.pretax_amount) > 0:
                all_records.append({
                    "账期": billing_cycle,
                    "产品代码(ProductCode)": item.product_code,
                    "产品名称(ProductName)": item.product_name,
                    "产品明细(ProductDetail)": item.product_detail,
                    "计费方式": item.subscription_type, # PayAsYouGo (按量) / Subscription (包年包月)
                    "地域(Region)": item.region,
                    "资源实例ID(InstanceID)": item.instance_id,
                    "实例昵称": item.instance_nick,
                    "计费项": item.billing_item,
                    "消费金额(元)": float(item.pretax_amount)
                })
        
        next_token = response.body.data.next_token
        if not next_token:
            break

    df = pd.DataFrame(all_records)
    return df

if __name__ == "__main__":
    # 分析最近 2 个月
    df = get_billing_services("2026-07")
    
    # 1. 汇总所有产生费用的服务清单
    summary_service = df.groupby(["产品代码(ProductCode)", "产品名称(ProductName)", "计费方式"])["消费金额(元)"].sum().reset_index()
    print("\n========== 产生费用的云服务汇总 ==========")
    print(summary_service.sort_values(by="消费金额(元)", ascending=False).to_string(index=False))
    
    # 2. 导出所有活跃计费资产清单到 Excel
    output_file = "aliyun_active_billing_assets.xlsx"
    with pd.ExcelWriter(output_file) as writer:
        summary_service.to_excel(writer, sheet_name="服务费用汇总", index=False)
        df.to_excel(writer, sheet_name="全部计费资产明细", index=False)
    print(f"\n[✓] 资产清单已成功导出至: {output_file}")
    

~~~

四、 最容易被遗漏的“隐形计费服务”排查清单
在梳理时，大家往往只关注 ECS、RDS、Redis 这些显性实例，以下这几类是费用暗坑，务必重点标注：
服务类别	隐形计费项	排查方式与说明
网络与流量 (Network)	• EIP (弹性公网IP)<br>• NAT 网关 CU 容量费 & 流量费<br>• 共享带宽包 / SLB 实例费	EIP 闲置未绑定 ECS 时按小时收取闲置费；NAT 网关按流经数据量计费。
存储与备份 (Storage)	• ECS 自动快照 (Snapshot)<br>• OSS 冷归档 / API 请求量<br>• NAS 存储包超量	机器删了但历史快照没删，每天都在产生小额扣费；OSS 跨区域复制流量。
安全与监控 (Observability)	• SLS 日志服务 (Logstore 索引量)<br>• ARMS 应用监控 / 云监控 Agent<br>• 云安全中心 (漏洞防护授权数)	日志写入量突增或索引保存天数过长导致费用激增。
域名与解析 (Domain/DNS)	• 云解析 PrivateZone / 递归解析<br>• SSL 证书自动续费	内部 VPC 域名解析查询量大时会按请求千万次计费。
五、 输出交付物建议（用于汇报与交接）
梳理完成后，建议输出一份清晰的 《云资产与费用架构拓扑表》，包含以下几个维度：
服务概览页：
产生费用的云产品数量（如：共涉及 14 款云产品）。
固定费用（包年包月） vs 弹性费用（按量付费）比例。


# 0913
面对**“机器数量多、文档模糊、单机混布（一台机器跑多个应用/容器/定时任务）”**的存量环境，人工一台台登录排查极易遗漏且效率低下。

推荐采用**“流量入口反推 + 自动化批量探针 + 依赖逆向测绘”**的三步排查法，可以在几天内把几十上百台混布机器摸得清清楚楚。

---

### 第一步：自顶向下，先抓“流量入口”（纲举目张）

混布系统里，直接看机器容易眼花，但**用户流量的入口只有那么几个**。顺着流量走，能迅速理清核心业务跑在哪。

1. **查负载均衡（ALB / SLB / CLB / Nginx）**：
   * 导出所有云账号下的负载均衡监听规则。
   * 查看**转发规则（Target Groups / 后端服务器组）**：域名/路径 -> 转发到了哪台机器（IP）的哪个端口（Port）。
   * *产出*：直接锁定 70% 以上承接业务流量的主力机器与应用端口。
2. **查 DNS 解析与 CDN**：
   * 收集公司所有域名，看解析记录指向了哪些公网 IP、EIP 或 SLB 地址。

---

### 第二步：利用云助手/Ansible 执行“自动化探针脚本”（解决机器多）

**千万不要手动 SSH 登录上百台机器！**
利用各家云平台的**免密运维通道**（AWS Systems Manager / 阿里云云助手 Cloud Assistant / Azure Run Command）或 Ansible，**批量下发同一套只读侦测脚本**。

#### 💡 万能的主机资产与混布排查脚本（Shell）
将以下脚本批量分发执行，输出为一个 JSON 或文本日志：

```bash
#!/bin/bash
echo "========== 1. 主机基本信息 =========="
hostname; hostname -I; uname -a

echo "========== 2. 正在监听的端口与对应进程 (核心排查) =========="
# 找出所有监听端口、PID及进程名
ss -tulpn | grep LISTEN || netstat -tulnp | grep LISTEN

echo "========== 3. 容器排查 (Docker/K8s) =========="
if command -v docker &> /dev/null; then
    # 打印运行中的容器名、镜像、端口映射、挂载目录
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}"
fi

echo "========== 4. 常驻与自启服务 (Systemd/Supervisor) =========="
systemctl list-units --type=service --state=running | head -n 30
if command -v supervisorctl &> /dev/null; then
    supervisorctl status
fi

echo "========== 5. 易被遗忘的定时任务 (Crontab) =========="
crontab -l 2>/dev/null
ls -la /etc/cron* 2>/dev/null

echo "========== 6. 关键进程启动工作目录 (精准定位代码在哪) =========="
# 抓取 Java / Node / Python / Go 等核心进程的工作目录
for pid in $(pgrep -d " " -f "java|node|python|gunicorn|dotnet"); do
    echo "PID: $pid | Dir: $(ls -l /proc/$pid/cwd 2>/dev/null | awk '{print $NF}') | Cmd: $(tr '\0' ' ' < /proc/$pid/cmdline 2>/dev/null | cut -c 1-200)"
done

echo "========== 7. 对外依赖连接 (识别连了哪些数据库/Redis/MQ) =========="
# 查看本机正在连外部哪些 IP 和端口（ESTABLISHED 状态）
ss -ant | awk '{print $5}' | grep -vE '127.0.0.1|0.0.0.0|\*|:' | sort | uniq -c | sort -nr | head -n 20
```

---

### 第三步：逆向解构“单机混布”的四大关键

探针脚本跑完后，针对单台混布机器，按以下 4 个维度进行“应用剥离”：

```text
混布机器 (IP: 10.0.1.50)
 ├── 端口 8080 ──> PID 1234 (Java) ──> 工作目录 /app/order-service ──> 连 RDS A
 ├── 端口 3000 ──> PID 5678 (Node) ──> 工作目录 /app/frontend-admin ──> 静态前端
 ├── 容器 redis-cluster ──> 端口 6379 ──> 本地混布的缓存中间件
 └── Crontab ──> 每天 02:00 跑 /scripts/sync_data.py (隐形数据同步任务)
```

1. **定位代码路径与工作目录**：
   * 通过 `pwdx <PID>` 或 `ls -l /proc/<PID>/cwd`，立刻知道这个进程的代码/jar包/二进制文件放在哪个目录下（例如 `/opt/web/payment`）。
2. **提取环境变量与配置文件**：
   * 去对应的工作目录下看 `application.properties`、`.env`、`config.yaml` 或直接查看进程环境变量：
     `cat /proc/<PID>/environ | tr '\0' '\n'`
   * 这里能直接拿到该应用连接的 **数据库 (RDS) 地址、Redis 地址、第三方 API Key**。
3. **识别日志路径与健康检查**：
   * 找该目录下的 `logs/` 或查看打开的文件句柄 `lsof -p <PID>`，确认日志打在哪里（后续接监控和收集用）。
4. **揪出隐形定时任务（极易漏掉）**：
   * 很多混布机器上跑着十几年前遗留下来的 Python/Shell 跑批脚本，务必检查 `crontab -l` 和 `/etc/crontab`。

---

### 第四步：输出《全局应用-主机混布拓扑总表》

把排查结果汇总为统一的盘点矩阵（CMDB 底表），这是后续迁移 CI/CD、重构或上容器的基准依据：

| 所属云/账号 | 主机私网 IP | 承载应用/服务名 | 运行方式 (进程/Docker) | 监听端口 | 代码/工作目录 | 依赖的外部资源 (DB/MQ) | 入口流量 (ALB/域名) | 备注 (是否可独立拆分) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| AWS-Prod (111) | `10.0.1.10` | `order-service` | Java (PID 1021) | 8080 | `/app/order` | RDS-MySQL (`10.0.5.20:3306`) | `api.xxx.com/order` | 混布了老旧同步脚本 |
| AWS-Prod (111) | `10.0.1.10` | `data-sync-job` | Cron (Python) | 无 | `/opt/scripts` | 同上 | 内部定时触发 | 建议后续迁移至云函数 |
| 阿里云-Prod (222) | `172.16.0.5` | `pay-gateway` | Docker 容器 | 8443:8443 | `/data/docker/...` | Redis (`r-xxx.redis.rds.aliyuncs.com`) | `pay.xxx.com` | 独立容器，易迁移 |

---

### 五、 核心避坑指南（排查混布常见盲区）

1. **警惕“僵尸进程”与“未下线老版本”**：
   * 经常会发现某台机器上起了 2 个 Java 进程，一个叫 `app-v1.jar`，一个叫 `app-v2.jar`。
   * **核验方法**：看端口谁在监听（`ss -tulpn`），看进程启动时间（`ps -eo pid,lstart,cmd | grep java`），看连接数，没有流量的就是死进程。
2. **不要漏掉本地起的文件存储/中间件**：
   * 很多老系统混布时，会在机器本地直接 `apt/yum install redis` 或 `nginx`，甚至把业务文件写在 `/data/upload` 本地目录。迁移流水线前必须把这些本地依赖记录下来。
3. **分批梳理，优先攻克核心业务**：
   * 不要试图一天理清 100 个；先利用第一步的 ALB 流量列表，挑出 **Top 20 核心业务应用** 进行深入剥离，跑顺一套模板，剩下的边缘服务套用模板就会极快。
  







要对多云环境下的大量混布机器进行**全量导出**并**排查访问量（评估是否退役下线）**，可以通过“云监控指标 + 负载均衡流量 + 主机网络底噪”三层数据来进行精准判定。

---

### 一、 准备工作：需要哪些资源与权限？

你不需要申请机器的 Root 写权限，只需准备**只读权限**和**命令行工具**即可：

1. **权限准备（每个云账号配置 ReadOnly）**：
   * **AWS**：`ReadOnlyAccess` 或至少包含 `EC2ReadOnlyAccess`、`ElasticLoadBalancingReadOnly`、`CloudWatchReadOnlyAccess`。
   * **阿里云**：`ReadOnlyAccess` 或 `AliyunECSReadOnlyAccess`、`AliyunSLBReadOnlyAccess`、`AliyunCloudMonitorReadOnlyAccess`。
   * **Azure**：订阅级别的 `Reader`（读取者）角色。
2. **工具环境**：
   * 本地或跳板机安装 `aws-cli`、`aliyun-cli`、`az-cli`。
   * Python 3 + `pandas`（用于一键将各云拉下来的 JSON 数据合并为统一 Excel）。

---

### 二、 如何一键导出资产与负载均衡列表？

使用各云官方 CLI，可直接批量导出机器列表和 LB 转发规则为 CSV/表格：

#### 1. AWS 资产与 ALB 导出
```bash
# 导出所有 EC2 实例 (ID, 私网IP, 公网IP, 实例名, 状态)
aws ec2 describe-instances \
  --query "Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,PublicIpAddress,Tags[?Key=='Name'].Value|[0],State.Name]" \
  --output table

# 导出所有 ALB 目标组及其绑定的后端机器和端口 (核心混布入口)
aws elbv2 describe-target-groups \
  --query "TargetGroups[*].[TargetGroupArn,TargetGroupName,Port,Protocol,VpcId]" \
  --output table
```

#### 2. 阿里云资产与 SLB 导出
```bash
# 导出所有 ECS 实例
aliyun ecs DescribeInstances \
  --output cols=InstanceId,InstanceName,PrivateIpAddresses.IpAddress[0],PublicIpAddresses.IpAddress[0],Status \
  --rows Instances.Instance[]

# 导出所有 SLB 负载均衡及其后端服务器
aliyun slb DescribeLoadBalancers \
  --output cols=LoadBalancerId,LoadBalancerName,Address,NetworkType,AddressType \
  --rows LoadBalancers.LoadBalancer[]
```

#### 3. Azure 资产导出
```bash
# 导出所有 VM 虚拟机
az vm list -d --query "[].[name,resourceGroup,privateIps,publicIps,powerState.displayStatus]" -o table
```

---

### 三、 如何查访问量？（用于退役/下线评估的核心方法）

评估一个应用或机器**“是否可以退役”**，切忌只看当前时刻。必须拉取 **过去 30 ~ 90 天** 的数据（防止踩到季度/月度定时跑批业务）。

#### 方法 1：从负载均衡（ALB/SLB）查请求量（最直观）
如果应用挂在 LB 后面，通过云监控直接拉取 **Request Count (请求总数) / QPS**：

* **AWS ALB**：进入 CloudWatch -> Metrics -> `ApplicationELB` -> 查 `RequestCount`（按目标组 Target Group 统计）。
  * *判定*：过去 30 天 `Sum(RequestCount)` 为 0 或极低（仅有健康检查流量），即可判定无外部业务流量。
* **阿里云 SLB**：进入 云监控 -> SLB 监控 -> 查 `QPS` 和 `ActiveConnection`（活跃连接数）。
  * *判定*：过去 30 天 QPS 平直且无抖动。
* **Azure App Gateway**：查看 Azure Monitor -> `Total Requests`。

#### 方法 2：无 LB 的机器，查主机网络 I/O（识别是否只有“心跳底噪”）
对于混布了内部服务、未挂公网 LB 的机器，直接看云监控的 **NetworkIn / NetworkOut（网络吞吐量）**：

* **指标观察法**：
  * **僵尸/废弃机器特征**：网络出入流量常年低于 **1~5 KB/s**（这条平直的线仅仅是云安全中心 Agent、NTP 时钟同步、系统日志的心跳底噪）。
  * **活跃机器特征**：每天有明显的峰谷波形，或网络流量达到 MB/s 级别。

#### 方法 3：主机层查活跃连接与 Access Log（精准到具体混布端口）
在一台混布了多个端口的机器上，看具体哪个端口没人用：

```bash
# 1. 查看当前各端口的外部连接数 (如果端口常年只有 0 个连接，基本处于闲置)
ss -ant | grep -E ':(8080|8081|3000)' | grep ESTAB | wc -l

# 2. 检查 Nginx / 应用 Access Log 的最后修改时间与写入量
ls -lh /var/log/nginx/*access.log
tail -n 100 /path/to/app/logs/access.log
```

---

### 四、 应用退役评估矩阵（决策树）

根据收集到的指标，将应用/机器划分为四类：

| 评估分类 | 指标特征 | 处置策略 |
| :--- | :--- | :--- |
| 🔴 **明确废弃 (高优先级退役)** | 过去 30~60 天 RequestCount = 0，Network I/O 仅有心跳底噪，无数据库连接 | **直接进入退役下线流程** |
| 🟡 **疑似死进程 (端口级退役)** | 机器上有其他流量，但某混布端口（如 8081）几个月无访问日志 | **下线该独立进程，释放单机内存** |
| 🔵 **周期性/低频业务** | 平时无流量，但在每月 1 号或每周日晚有明显的 CPU/网络脉冲 | **保留，属于跑批/月结任务，切勿误杀** |
| 🟢 **主力活跃业务** | 持续产生稳定 QPS 和网络流量 | **纳入新 CI/CD 纳管范围** |

---

### 五、 安全退役“四步下线法”（绝对不背锅的 SOP）

对于评估出来“没有访问量、建议退役”的应用和机器，**严禁直接 Terminate / 销毁**，按照以下步骤操作可保证 100% 安全：

```text
[1. 移出流量] ──> [2. 关停进程/停机] ──> [3. 快照冷备份] ──> [4. 延期 14 天销毁]
 (解绑 DNS/LB)      (观察 7 天是否报错)      (保留系统盘 Snapshot)     (彻底释放降本)
```

1. **第 1 步（解绑流量入口）**：先从 DNS 解析或 ALB/SLB Target Group 中剔除（或禁用监听端口），观察 **3~7 天** 看是否有其他业务团队报障。
2. **第 2 步（停止实例/进程 Stop）**：7 天无异常后，执行 `Stop-Instance`（停机但保留磁盘），停机状态不再收取计算费用。
3. **第 3 步（制作快照冷备份 Snapshot）**：打一份全盘系统快照（AMI / Snapshot），归档留存。
4. **第 4 步（彻底释放 Terminate）**：停机放置 **14~30 天** 后，若全公司仍无人认领，直接释放机器，完成彻底退役与账单降本。
核心资源台账（对齐业务）：
实例ID ➔ 公网/内网IP ➔ 对应环境 (生产/测试/预发) ➔ 负责团队/业务模块。
优化与缩容建议（快速产出业务价值）：
闲置资源：0 流量的 SLB、未绑定的 EIP、已下线主机的残留快照。
计费模式优化：长期运行的按量 ECS/RDS 转为包年包月或购买节省计划（Savings Plans）。
需要进一步针对某几个具体产品（如 ECS/VPC/RDS）生成深度巡检脚本或架构拓扑图，可以随时告诉我！
