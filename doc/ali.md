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
