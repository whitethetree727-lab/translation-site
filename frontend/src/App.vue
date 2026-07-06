<template>
  <div id="app" style="font-family: Arial, sans-serif; max-width: 800px; margin: 40px auto; padding: 20px;">
    <h1 style="color: #2c3e50; border-bottom: 3px solid #42b883; padding-bottom: 10px;">📚 我的翻译作品</h1>
    
    <!-- 如果未登录，显示登录框 -->
    <div v-if="!isLoggedIn" style="background: #f0f4ff; padding: 30px; border-radius: 12px; border: 1px solid #ccc;">
      <h3>🔐 管理员登录</h3>
      <p style="color: #666;">请输入管理员密码以上传图片</p>
      <div style="display: flex; gap: 10px;">
        <input type="password" v-model="password" placeholder="输入密码 admin123" 
               style="flex:1; padding: 10px; border: 1px solid #ddd; border-radius: 6px;">
        <button @click="login" style="padding: 10px 24px; background: #42b883; color: white; border: none; border-radius: 6px; cursor: pointer;">
          登录
        </button>
      </div>
      <div v-if="loginError" style="color: red; margin-top: 10px;">密码错误，请重试</div>
    </div>

    <!-- 已登录 -> 展示内容 -->
    <div v-else>
      <!-- 上传区域 -->
      <div style="background: #f8f9fa; padding: 20px; border-radius: 12px; margin-bottom: 20px; border: 2px dashed #42b883;">
        <h3>⬆️ 上传翻译图片</h3>
        <div style="display: flex; flex-direction: column; gap: 12px;">
          <!-- 显示当前选中的分类 -->
          <div style="display: flex; gap: 10px; align-items: center; background: #fff; padding: 8px 12px; border: 1px solid #ccc; border-radius: 6px;">
            <span style="font-weight: bold;">📌 目标分类：</span>
            <span v-if="selectedCategoryId" style="color: #198754; font-weight: bold;">{{ selectedCategoryName }} (ID: {{ selectedCategoryId }})</span>
            <span v-else style="color: #6c757d;">请从下方分类列表点击选中</span>
            <button v-if="selectedCategoryId" @click="clearSelection" 
                    style="margin-left: auto; padding: 4px 12px; background: #dc3545; color: white; border: none; border-radius: 4px; cursor: pointer;">
              清除
            </button>
          </div>
          <input type="file" @change="handleFileUpload" accept="image/*" style="padding: 8px;">
          <input type="text" v-model="source" placeholder="图片来源（如：推特匿名提问）" style="padding: 10px; border-radius: 6px; border: 1px solid #ccc;">
          <textarea v-model="note" placeholder="翻译备注/说明" style="padding: 10px; border-radius: 6px; border: 1px solid #ccc;"></textarea>
          <button @click="uploadImage" :disabled="!selectedFile || !selectedCategoryId" style="padding: 12px; background: #198754; color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: bold;">
            📤 上传到服务器
          </button>
          <div v-if="uploadMessage" style="padding: 10px; background: #d1e7dd; border-radius: 6px;">{{ uploadMessage }}</div>
        </div>
      </div>

      <!-- 原有的分类列表 -->
      <div v-if="loading">加载中...</div>
      <div v-else>
        <div v-for="cat in categories" :key="cat.category_id" 
             style="background: #f8f9fa; margin: 10px 0; padding: 15px 20px; border-radius: 8px; 
                    box-shadow: 0 1px 3px rgba(0,0,0,0.1); cursor: pointer; display: flex; align-items: center; gap: 12px;"
             @click="fetchChildren(cat.category_id)">
          <span>📂</span>
          <span style="font-weight: bold; font-size: 18px;">{{ cat.name }}</span>
          <span style="margin-left: auto; font-size: 14px; color: #6c757d;">点击展开</span>
        </div>

        <div v-if="children.length > 0" style="margin-top: 20px; padding: 15px; background: #f1f3f5; border-radius: 8px;">
          <h3>📁 子板块</h3>
          <ul style="list-style: none; padding: 0;">
            <li v-for="child in children" :key="child.category_id" 
                @click="selectCategory(child)"
                style="padding: 8px 12px; background: white; margin: 5px 0; border-radius: 4px; border-left: 4px solid #42b883; cursor: pointer; transition: background 0.2s;"
                @mouseenter="(e) => e.currentTarget.style.background='#e9ecef'"
                @mouseleave="(e) => e.currentTarget.style.background='white'">
              {{ child.name }}
            </li>
          </ul>
        </div>
      </div>
    </div>

    <div style="margin-top: 30px; padding: 10px; background: #e8f5e9; border-radius: 4px; text-align: center; color: #2e7d32;">
      ✅ 状态：{{ apiStatus }}
    </div>
  </div>
</template>

<script>
import axios from 'axios'

export default {
  data() {
    return {
      // 登录
      isLoggedIn: false,
      password: '',
      loginError: false,
      
      // 上传
      selectedCategory: '',      // 保留，但不再使用（为了兼容，可保留）
      selectedCategoryId: null,  // 选中的分类ID
      selectedCategoryName: '',  // 选中的分类名称
      selectedFile: null,
      source: '',
      note: '',
      uploadMessage: '',
      
      // 分类
      categories: [],
      children: [],
      loading: true,
      apiStatus: '连接中...'
    }
  },
  async mounted() {
    await this.fetchCategories()
  },
  methods: {
    // 登录
    async login() {
      const formData = new FormData()
      formData.append('password', this.password)
      try {
        const res = await axios.post('/api/login', formData)
        if (res.data.success) {
          this.isLoggedIn = true
          this.loginError = false
          this.apiStatus = '管理员已登录 ✅'
        }
      } catch (e) {
        this.loginError = true
        this.password = ''
      }
    },
    
    // 获取分类
    async fetchCategories() {
      try {
        const res = await axios.get('/api/categories/root')
        this.categories = res.data.data
        this.apiStatus = '已连接到后端 ✅'
      } catch (e) {
        this.apiStatus = '连接后端失败 ❌'
      } finally {
        this.loading = false
      }
    },
    
    // 文件选择
    handleFileUpload(event) {
      this.selectedFile = event.target.files[0]
    },
    
    // 选择分类
    selectCategory(cat) {
      this.selectedCategoryId = cat.category_id
      this.selectedCategoryName = cat.name
      this.uploadMessage = `已选中分类：${cat.name} (ID: ${cat.category_id})`
    },

    // 清除选中分类
    clearSelection() {
      this.selectedCategoryId = null
      this.selectedCategoryName = ''
      this.uploadMessage = ''
    },
    
    // 上传图片
    async uploadImage() {
      if (!this.selectedFile) return alert('请先选择图片')
      if (!this.selectedCategoryId) return alert('请先点击选择一个分类')
      
      const formData = new FormData()
      formData.append('file', this.selectedFile)
      formData.append('category_id', this.selectedCategoryId)
      formData.append('original_source', this.source)
      formData.append('translation_note', this.note)
      
      try {
        const res = await axios.post('/api/upload', formData, {
          headers: { 'Content-Type': 'multipart/form-data' }
        })
        this.uploadMessage = `✅ 上传成功！文件名：${res.data.filename}`
        // 清空表单
        this.selectedFile = null
        this.source = ''
        this.note = ''
        document.querySelector('input[type="file"]').value = ''
        // 不清除分类选择，方便连续上传
      } catch (e) {
        this.uploadMessage = '❌ 上传失败，请检查后端日志'
        console.error(e)
      }
    },
    
    // 获取子分类
    async fetchChildren(parentId) {
      try {
        const res = await axios.get(`/api/categories/${parentId}/children`)
        this.children = res.data.data
      } catch (e) {
        alert('获取子分类失败')
      }
    }
  }
}
</script>