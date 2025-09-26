import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { DefaultApolloClient } from '@vue/apollo-composable'
import Toast from 'vue-toastification'
import 'vue-toastification/dist/index.css'
import apolloClient from './apollo'
import './style.css'
import App from './App.vue'
import router from './router'

const app = createApp(App)
const pinia = createPinia()

app.use(pinia)
app.use(router)
app.use(Toast)
app.provide(DefaultApolloClient, apolloClient)
app.mount('#app')
