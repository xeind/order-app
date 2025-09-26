<template>
  <div v-if="cartStore.isOpen" class="fixed inset-0 z-50 overflow-hidden">
    <!-- Backdrop -->
    <div
      class="absolute inset-0 bg-black bg-opacity-50"
      @click="cartStore.closeCart"
    ></div>
    
    <!-- Cart Sidebar -->
    <div class="absolute right-0 top-0 flex h-full w-96 flex-col bg-white shadow-xl">
      <!-- Header -->
      <div class="flex items-center justify-between border-b p-4">
        <h2 class="text-lg font-semibold text-gray-900">Shopping Cart</h2>
        <button
          @click="cartStore.closeCart"
          class="text-gray-400 hover:text-gray-600"
        >
          <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M6 18L18 6M6 6l12 12"
            />
          </svg>
        </button>
      </div>
      
      <!-- Cart Items -->
      <div class="flex-1 overflow-y-auto p-4">
        <div v-if="cartStore.items.length === 0" class="text-center py-8">
          <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4m0 0L7 13m0 0l-2.5 5M7 13v8a2 2 0 002 2h6a2 2 0 002-2v-8"></path>
          </svg>
          <p class="mt-2 text-gray-500">Your cart is empty</p>
        </div>
        
        <div v-else class="space-y-4">
          <div
            v-for="item in cartStore.items"
            :key="item.id"
            class="flex items-center space-x-4 rounded-lg border p-4"
          >
            <!-- Product Image -->
            <div class="h-16 w-16 flex-shrink-0 overflow-hidden rounded-lg">
              <img
                v-if="item.photoUrl"
                :src="item.photoUrl"
                :alt="item.name"
                class="h-full w-full object-cover"
              />
              <div
                v-else
                class="flex h-full w-full items-center justify-center bg-gray-100 text-gray-400"
              >
                <svg class="h-8 w-8" fill="currentColor" viewBox="0 0 20 20">
                  <path
                    fill-rule="evenodd"
                    d="M4 3a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V5a2 2 0 00-2-2H4zm12 12H4l4-8 3 6 2-4 3 6z"
                    clip-rule="evenodd"
                  />
                </svg>
              </div>
            </div>
            
            <!-- Product Info -->
            <div class="flex-1">
              <h3 class="text-sm font-medium text-gray-900">{{ item.name }}</h3>
              <p class="text-sm text-gray-600">₱{{ formatPrice(item.price) }}</p>
              
              <!-- Quantity Controls -->
              <div class="mt-2 flex items-center space-x-2">
                <button
                  @click="cartStore.updateQuantity(item.id, item.quantity - 1)"
                  class="rounded bg-gray-200 px-2 py-1 text-sm hover:bg-gray-300"
                  :disabled="item.quantity <= 1"
                >
                  -
                </button>
                <span class="px-2 text-sm">{{ item.quantity }}</span>
                <button
                  @click="increaseQuantity(item)"
                  :disabled="!!(item.stockQuantity && item.quantity >= item.stockQuantity)"
                  :class="[
                    'rounded px-2 py-1 text-sm transition-colors',
                    item.stockQuantity && item.quantity >= item.stockQuantity
                      ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                      : 'bg-gray-200 hover:bg-gray-300'
                  ]"
                >
                  +
                </button>
                <button
                  @click="cartStore.removeItem(item.id)"
                  class="ml-auto text-red-600 hover:text-red-800"
                >
                  Remove
                </button>
              </div>
            </div>
            
            <!-- Item Total -->
            <div class="text-sm font-medium text-gray-900">
              ₱{{ formatPrice(item.price * item.quantity) }}
              </div>
              
              <!-- Stock info -->
              <div v-if="item.stockQuantity" class="text-xs text-gray-500 mt-1">
                Stock: {{ item.stockQuantity }}
              </div>
            </div>
        </div>
      </div>
      
      <!-- Footer -->
      <div v-if="cartStore.items.length > 0" class="border-t p-4">
        <div class="mb-4 flex justify-between text-lg font-semibold">
          <span>Total:</span>
          <span>₱{{ formatPrice(cartStore.subtotal) }}</span>
        </div>
        
        <div class="space-y-2">
          <button
            @click="proceedToCheckout"
            class="w-full rounded bg-blue-600 px-4 py-2 text-white hover:bg-blue-700"
          >
            Proceed to Checkout
          </button>
          <button
            @click="cartStore.clearCart"
            class="w-full rounded bg-gray-200 px-4 py-2 text-gray-700 hover:bg-gray-300"
          >
            Clear Cart
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useCartStore } from '../stores/cart'
import { useRouter } from 'vue-router'
import { useToast } from 'vue-toastification'

const cartStore = useCartStore()
const router = useRouter()
const toast = useToast()

const formatPrice = (price: number): string => {
  return price.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',')
}

const increaseQuantity = (item: any) => {
  const success = cartStore.updateQuantity(item.id, item.quantity + 1)
  if (!success && item.stockQuantity) {
    toast.warning(`Cannot add more items. Only ${item.stockQuantity} in stock.`)
  }
}

const proceedToCheckout = () => {
  console.log('CartSidebar: proceedToCheckout called')
  console.log('CartSidebar: Current cart items:', cartStore.items.length)
  
  // Close cart and navigate to orders page in Create New Order mode
  cartStore.closeCart()
  console.log('CartSidebar: Navigating to /orders with mode=create')
  router.push({ path: '/orders', query: { mode: 'create' } })
}
</script>