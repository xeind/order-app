<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Navigation Header -->
    <nav v-if="authStore.isAuthenticated" class="border-b bg-white shadow-sm">
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div class="flex h-16 items-center justify-between">
          <div class="flex flex-shrink-0 items-center">
            <h1 class="text-xl font-bold text-gray-900">Gosyomo</h1>
          </div>
          <div class="flex space-x-8">
            <button
              @click="$router.push('/products')"
              :class="[
                'whitespace-nowrap border-b-2 border-transparent px-1 py-2 text-sm font-medium transition-colors',
                $route.path === '/products'
                  ? 'border-blue-500 text-gray-900'
                  : 'text-gray-500 hover:border-gray-300 hover:text-gray-700'
              ]"
            >
              Product Manager
            </button>

            <button
              @click="$router.push('/orders')"
              :class="[
                'whitespace-nowrap border-b-2 border-transparent px-1 py-2 text-sm font-medium transition-colors',
                $route.path === '/orders'
                  ? 'border-blue-500 text-gray-900'
                  : 'text-gray-500 hover:border-gray-300 hover:text-gray-700'
              ]"
            >
              Order Manager
            </button>
          </div>
          <div class="flex items-center space-x-4">
            <!-- Cart Icon -->
            <button
              @click="cartStore.toggleCart"
              class="relative rounded-full p-2 text-gray-600 hover:text-gray-900"
            >
              <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M3 3h2l.4 2M7 13h10l4-8H5.4m0 0L7 13m0 0l-2.5 5M7 13v8a2 2 0 002 2h6a2 2 0 002-2v-8m4-5a2 2 0 11-4 0 2 2 0 014 0z"
                />
              </svg>
              <!-- Cart Count Badge -->
              <span
                v-if="cartStore.itemCount > 0"
                class="absolute -top-1 -right-1 flex h-5 w-5 items-center justify-center rounded-full bg-red-600 text-xs font-medium text-white"
              >
                {{ cartStore.itemCount > 99 ? '99+' : cartStore.itemCount }}
              </span>
            </button>

            <span class="text-sm text-gray-600">
              {{ authStore.user?.email }} ({{ authStore.user?.role }})
            </span>
            <button
              @click="handleLogout"
              class="rounded bg-red-600 px-3 py-1 text-sm text-white hover:bg-red-700"
            >
              Logout
            </button>
          </div>
        </div>
      </div>
    </nav>

    <!-- Main Content -->
    <main>
      <router-view :key="$route.path" />
    </main>

    <!-- Cart Sidebar -->
    <CartSidebar />
  </div>
</template>

<script setup lang="ts">
import { useAuthStore } from './stores/auth'
import { useCartStore } from './stores/cart'
import { useRouter } from 'vue-router'
import CartSidebar from './components/CartSidebar.vue'

const authStore = useAuthStore()
const cartStore = useCartStore()
const router = useRouter()

const handleLogout = () => {
  authStore.logout()
  router.push('/login')
}
</script>
