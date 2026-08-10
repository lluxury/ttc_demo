<script setup>
import { ref } from 'vue'
import axios from 'axios'

const count = ref(0)  // 定义一个响应式变量，初始为 0

// ========== 登录状态 ==========
const isLoggedIn = ref(false)
const username = ref('')
const password = ref('')
const loginError = ref('')

// ========== 计算模块状态 ==========
const empId = ref('1001')
const calcResult = ref(null)
const calcLoading = ref(false)

// ========== 模板模块状态 ==========
const templateName = ref('销售季度KPI')
const templateResult = ref(null)
const templateLoading = ref(false)

// ========== 登录逻辑（写死账号密码） ==========
const handleLogin = () => {
  if (username.value === 'admin' && password.value === '123456') {
    isLoggedIn.value = true
    loginError.value = ''
  } else {
    loginError.value = '用户名或密码错误（请使用 admin / 123456）'
  }
}

// ========== 功能1：计算绩效 ==========
const handleCalc = async () => {
  calcLoading.value = true
  calcResult.value = null
  try {
    const res = await axios.post('/api/score/calc', {
      employeeId: parseInt(empId.value) || 1001,
      // 这里固定用了我们测试过的数据（英文键，匹配默认模板）
      scoreMap: {
        codeQuality: 95,
        responseSpeed: 80,
        teamwork: 70
      }
    })
    if (res.data.code === 200) {
      calcResult.value = res.data.data
    } else {
      alert('计算失败: ' + res.data.msg)
    }
  } catch (e) {
    alert('请求失败，请确认后端服务是否在 8080 端口运行')
  } finally {
    calcLoading.value = false
  }
}

// ========== 功能2：创建模板 ==========
const handleCreateTemplate = async () => {
  templateLoading.value = true
  templateResult.value = null
  try {
    const res = await axios.post('/api/management/template', {
      name: templateName.value || '默认模板',
      baseScore: 100,
      weights: {
        sales: 0.5,
        satisfaction: 0.3,
        collection: 0.2
      }
    })
    if (res.data.code === 200) {
      templateResult.value = res.data.data
    } else {
      alert('创建失败: ' + res.data.msg)
    }
  } catch (e) {
    alert('请求失败，请确认后端服务是否在 8080 端口运行')
  } finally {
    templateLoading.value = false
  }
}
</script>

<template>
  <div id="app">
    <!-- ====== 登录页 ====== -->
    <div v-if="!isLoggedIn" class="login-container">
      <div class="login-box">
        <h1>⚡ 绩效</h1>
        <p style="color: #888;">默认账号: admin / 密码: 123456</p>
        <input v-model="username" type="text" placeholder="请输入用户名" />
        <input v-model="password" type="password" placeholder="请输入密码" />
        <button @click="handleLogin">登 录</button>
        <button @click="count++" style="margin-top:10px; background:#52c41a;">
  点我计数: {{ count }}
</button>
        <p v-if="loginError" class="error">{{ loginError }}</p>
      </div>
    </div>

    <!-- ====== 主页（登录后） ====== -->
    <div v-else class="dashboard">
      <div class="header">
        <h2>👋 欢迎回来, {{ username }}</h2>
        <button class="logout" @click="isLoggedIn = false">退出登录</button>
      </div>

      <div class="row">
        <!-- 卡片1：计算绩效 -->
        <div class="card">
          <h3>📊 计算绩效</h3>
          <div class="field">
            <label>员工 ID：</label>
            <input v-model="empId" type="number" />
          </div>
          <button @click="handleCalc" :disabled="calcLoading">
            {{ calcLoading ? '计算中...' : '开始计算 (默认模板)' }}
          </button>
          <div v-if="calcResult" class="result">
            <p>总分：<strong>{{ calcResult.totalScore }}</strong></p>
            <p>等级：<span class="grade">{{ calcResult.grade }}</span></p>
          </div>
        </div>

        <!-- 卡片2：创建模板 -->
        <div class="card">
          <h3>📝 创建新模板</h3>
          <div class="field">
            <label>模板名称：</label>
            <input v-model="templateName" placeholder="例如：销售季度KPI" />
          </div>
          <button @click="handleCreateTemplate" :disabled="templateLoading">
            {{ templateLoading ? '创建中...' : '创建模板 (固定权重)' }}
          </button>
          <div v-if="templateResult" class="result">
            <p>✅ 创建成功！</p>
            <p>模板 ID：<strong>{{ templateResult.id }}</strong></p>
            <p>名称：{{ templateResult.name }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* ===== 全局重置 & 布局 ===== */
* {
  box-sizing: border-box;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}
#app {
  min-height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  background: #f0f2f5;
  margin: 0;
}

/* ===== 登录样式 ===== */
.login-container {
  display: flex;
  justify-content: center;
  align-items: center;
  width: 100%;
}
.login-box {
  background: white;
  padding: 40px 35px;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  width: 340px;
  text-align: center;
}
.login-box h1 {
  margin-bottom: 5px;
  color: #1a1a2e;
}
.login-box input {
  width: 100%;
  padding: 12px;
  margin: 8px 0;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 14px;
}
.login-box button {
  width: 100%;
  padding: 12px;
  background: #722ed1;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 16px;
  font-weight: bold;
  cursor: pointer;
  margin-top: 10px;
}
.login-box button:hover {
  background: #0958d9;
}
.error {
  color: #ff4d4f;
  margin-top: 10px;
  font-size: 14px;
}

/* ===== 主页样式 ===== */
.dashboard {
  width: 100%;
  max-width: 1000px;
  padding: 30px;
}
.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: white;
  padding: 15px 25px;
  border-radius: 10px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
  margin-bottom: 30px;
}
.header h2 {
  margin: 0;
  color: #1a1a2e;
}
.logout {
  background: #ff4d4f;
  color: white;
  border: none;
  padding: 8px 18px;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 500;
}
.logout:hover {
  background: #d9363e;
}

.row {
  display: flex;
  gap: 30px;
  flex-wrap: wrap;
}
.card {
  flex: 1;
  min-width: 280px;
  background: white;
  padding: 25px;
  border-radius: 12px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
  border: 1px solid #eee;
}
.card h3 {
  margin-top: 0;
  color: #1a1a2e;
  border-bottom: 2px solid #f0f2f5;
  padding-bottom: 10px;
}
.field {
  margin: 15px 0;
}
.field label {
  font-weight: 500;
  margin-right: 10px;
}
.field input {
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  width: 150px;
}
.card button {
  background: #1677ff;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 500;
  margin: 10px 0;
  width: 100%;
  transition: 0.2s;
}
.card button:hover:not(:disabled) {
  background: #0958d9;
}
.card button:disabled {
  background: #ccc;
  cursor: not-allowed;
}
.result {
  margin-top: 15px;
  padding: 15px;
  background: #f6ffed;
  border: 1px solid #b7eb8f;
  border-radius: 6px;
}
.result p {
  margin: 5px 0;
}
.grade {
  display: inline-block;
  background: #1677ff;
  color: white;
  padding: 2px 12px;
  border-radius: 20px;
  font-weight: bold;
}
</style>