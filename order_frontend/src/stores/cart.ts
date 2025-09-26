import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export interface CartItem {
  id: string
  name: string
  price: number
  quantity: number
  photoUrl?: string
  stockQuantity?: number
}

export const useCartStore = defineStore('cart', () => {
  // Initialize from localStorage if available
  let savedItems: CartItem[] = []
  try {
    const saved = localStorage.getItem('cart-items')
    if (saved) {
      savedItems = JSON.parse(saved)
    }
  } catch (error) {
    console.warn('Failed to load cart from localStorage:', error)
  }
  
  const items = ref<CartItem[]>(savedItems)
  const isOpen = ref(false)

  // Save to localStorage whenever items change
  const saveToLocalStorage = () => {
    try {
      localStorage.setItem('cart-items', JSON.stringify(items.value))
    } catch (error) {
      console.warn('Failed to save cart to localStorage:', error)
    }
  }

  // Computed properties
  const itemCount = computed(() => {
    return items.value.reduce((total, item) => total + item.quantity, 0)
  })

  const subtotal = computed(() => {
    return items.value.reduce((total, item) => total + (item.price * item.quantity), 0)
  })

  // Actions
  const addItem = (product: { id: string, name: string, price: number, photoUrl?: string, stockQuantity?: number }, quantity = 1) => {
    const existingItem = items.value.find(item => item.id === product.id)
    
    if (existingItem) {
      // Check stock limit before adding more
      const newQuantity = existingItem.quantity + quantity
      if (product.stockQuantity && newQuantity > product.stockQuantity) {
        console.warn(`Cannot add more items. Only ${product.stockQuantity} in stock.`)
        return false
      }
      existingItem.quantity = newQuantity
      // Update stock info if provided
      if (product.stockQuantity) {
        existingItem.stockQuantity = product.stockQuantity
      }
    } else {
      // Check if we can add the initial quantity
      if (product.stockQuantity && quantity > product.stockQuantity) {
        console.warn(`Cannot add ${quantity} items. Only ${product.stockQuantity} in stock.`)
        return false
      }
      items.value.push({
        id: product.id,
        name: product.name,
        price: product.price,
        quantity,
        photoUrl: product.photoUrl,
        stockQuantity: product.stockQuantity
      })
    }
    saveToLocalStorage()
    return true
  }

  const removeItem = (productId: string) => {
    const index = items.value.findIndex(item => item.id === productId)
    if (index > -1) {
      items.value.splice(index, 1)
      saveToLocalStorage()
    }
  }

  const updateQuantity = (productId: string, quantity: number) => {
    const item = items.value.find(item => item.id === productId)
    if (item) {
      if (quantity <= 0) {
        removeItem(productId)
      } else {
        // Check stock limit if available
        if (item.stockQuantity && quantity > item.stockQuantity) {
          console.warn(`Cannot set quantity to ${quantity}. Only ${item.stockQuantity} in stock.`)
          return false
        }
        item.quantity = quantity
        saveToLocalStorage()
        return true
      }
    }
    return false
  }

  const clearCart = () => {
    items.value = []
    saveToLocalStorage()
  }

  const toggleCart = () => {
    isOpen.value = !isOpen.value
  }

  const openCart = () => {
    isOpen.value = true
  }

  const closeCart = () => {
    isOpen.value = false
  }

  const getCartItemsForOrder = () => {
    return items.value.map(item => ({
      product: {
        id: item.id,
        name: item.name,
        price: item.price,
        photoUrl: item.photoUrl,
        stockQuantity: 999 // We'll assume stock is available for now
      },
      quantity: item.quantity
    }))
  }

  return {
    items,
    isOpen,
    itemCount,
    subtotal,
    addItem,
    removeItem,
    updateQuantity,
    clearCart,
    toggleCart,
    openCart,
    closeCart,
    getCartItemsForOrder
  }
})