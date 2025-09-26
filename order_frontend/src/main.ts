import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { DefaultApolloClient } from '@vue/apollo-composable'
import Toast from 'vue-toastification'
import 'vue-toastification/dist/index.css'
import apolloClient from './apollo'
import './style.css'
import App from './App.vue'
import router from './router'

console.log('Starting app initialization...')
console.log('API URL:', import.meta.env.VITE_API_URL)
console.log('Environment:', import.meta.env.VITE_APP_ENV)

try {
  const app = createApp(App)
  const pinia = createPinia()

  app.use(pinia)
  app.use(router)
  app.use(Toast)
  app.provide(DefaultApolloClient, apolloClient)
  
  console.log('Mounting app...')
  app.mount('#app')
  console.log('App mounted successfully!')
} catch (error) {
  console.error('Failed to initialize app:', error)
  const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred'
  document.body.innerHTML = `
    <div style="padding: 20px; color: red;">
      <h1>Application Error</h1>
      <p>Failed to initialize application: ${errorMessage}</p>
      <p>Check console for more details.</p>
    </div>
  `
}
