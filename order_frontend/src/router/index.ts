import { createRouter, createWebHistory } from 'vue-router'
import ProductManager from '../views/ProductManager.vue'
import UnifiedOrders from '../views/UnifiedOrders.vue'
import LoginForm from '../components/LoginForm.vue'
import { useAuthStore } from '../stores/auth'

const router = createRouter({
    history: createWebHistory(import.meta.env.BASE_URL),
    routes: [
        {
            path: '/login',
            name: 'login',
            component: LoginForm,
            meta: { requiresGuest: true },
        },
        {
            path: '/',
            redirect: '/products',
            meta: { requiresAuth: true },
        },
        {
            path: '/products',
            name: 'products',
            component: ProductManager,
            meta: { requiresAuth: true },
        },
        {
            path: '/orders',
            name: 'orders',
            component: UnifiedOrders,
            meta: { requiresAuth: true },
        },
        // Legacy redirects for backward compatibility
        {
            path: '/create-order',
            redirect: '/orders',
            meta: { requiresAuth: true },
        },
    ],
})

// Navigation guard for authentication
router.beforeEach(async (to, _from, next) => {
    console.log('Router guard executing for:', to.path)
    
    try {
        const authStore = useAuthStore()
        console.log('Auth state:', { isAuthenticated: authStore.isAuthenticated, hasUser: !!authStore.user })

        if (to.meta.requiresAuth && !authStore.isAuthenticated) {
            console.log('Redirecting to login - not authenticated')
            next('/login')
            return
        }

        if (to.meta.requiresGuest && authStore.isAuthenticated) {
            console.log('Redirecting to home - already authenticated')
            next('/')
            return
        }

        console.log('Proceeding to route:', to.path)
        next()
    } catch (error) {
        console.error('Router guard error:', error)
        next('/login')
    }
})

export default router
