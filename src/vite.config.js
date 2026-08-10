import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:8080',  // 指向你的 Java 后端
        changeOrigin: true,
        rewrite: (path) => path          // 保留 /api 路径
      }
    }
  }
})