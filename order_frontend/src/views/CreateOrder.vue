<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'

// Workflow steps
type WorkflowStep = 'customer' | 'products' | 'checkout'
const currentStep = ref<WorkflowStep>('customer')

// Formatting functions
const formatNumberWithCommas = (value: string): string => {
  // Remove any non-digit characters except decimal point
  const cleanValue = value.replace(/[^\d.]/g, '')

  // Split into integer and decimal parts
  const parts = cleanValue.split('.')
  const integerPart = parts[0] || '0'
  const decimalPart = parts[1] ? '.' + parts[1] : ''

  // Add commas to integer part
  const formattedInteger = integerPart.replace(/\B(?=(\d{3})+(?!\d))/g, ',')

  return formattedInteger + decimalPart
}

const formatPrice = (price: number): string => {
  return formatNumberWithCommas(price.toFixed(2))
}

interface Category {
  id: string
  name: string
  description: string
}

interface Product {
  id: string
  name: string
  description: string
  price: number
  category: Category
  productType: string | null
  photoUrl: string | null
  stockQuantity: number
  createdAt: string
  updatedAt: string
}

interface Customer {
  id: string
  email: string
  mobile: string | null
}

interface CartItem {
  product: Product
  quantity: number
}

// Order type
const orderType = ref<'in-store' | 'online'>('in-store')

// Customer management
const customerSearch = ref('')
const customerSearchResults = ref<Customer[]>([])
const selectedCustomer = ref<Customer | null>(null)
const showCustomerDropdown = ref(false)
const newCustomer = ref({ firstName: '', lastName: '', email: '', mobile: '' })
const creatingCustomer = ref(false)
const customerError = ref('')

// Products
const products = ref<Product[]>([])
const categories = ref<Category[]>([])
const productsLoading = ref(false)
const productSearch = ref('')
const selectedCategory = ref('')

// Cart management
const cartItems = ref<CartItem[]>([])

// Order creation
const shippingMethod = ref('standard')
const paymentMethod = ref('cash')
const creatingOrder = ref(false)

// Order success modal
const showSuccessModal = ref(false)
const successOrderData = ref<any>(null)

// Delivery information for online orders
const deliveryInfo = ref({
  fullName: '',
  address: '',
  city: '',
  postalCode: '',
  phone: '',
  instructions: ''
})

// Computed properties
const filteredProducts = computed(() => {
  let filtered = products.value

  if (productSearch.value) {
    const search = productSearch.value.toLowerCase()
    filtered = filtered.filter(p =>
      p.name.toLowerCase().includes(search) ||
      p.description?.toLowerCase().includes(search)
    )
  }

  if (selectedCategory.value) {
    filtered = filtered.filter(p => p.category.id === selectedCategory.value)
  }

  return filtered
})

const subtotal = computed(() => {
  return cartItems.value.reduce((sum, item) => sum + (item.product.price * item.quantity), 0)
})

const shippingCost = computed(() => {
  if (orderType.value === 'in-store') return 0

  switch (shippingMethod.value) {
    case 'standard': return 250.00  // ₱250
    case 'express': return 750.00   // ₱750
    case 'overnight': return 1250.00 // ₱1,250
    default: return 250.00
  }
})

const total = computed(() => {
  return subtotal.value + shippingCost.value
})

// Customer functions
const searchCustomers = async () => {
  if (customerSearch.value.length < 2) {
    customerSearchResults.value = []
    showCustomerDropdown.value = false
    return
  }

  try {
    const response = await fetch('http://localhost:3000/graphql', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        query: `
          query SearchCustomers($search: String!) {
            searchCustomers(search: $search) {
              id
              email
              mobile
            }
          }
        `,
        variables: {
          search: customerSearch.value,
        },
      }),
    })

    const data = await response.json()
    if (data.data) {
      customerSearchResults.value = data.data.searchCustomers
      showCustomerDropdown.value = true
    }
  } catch (err) {
    console.error('Error searching customers:', err)
  }
}

const selectCustomer = (customer: Customer) => {
  selectedCustomer.value = customer
  customerSearch.value = customer.email
  showCustomerDropdown.value = false
}

const clearCustomer = () => {
  selectedCustomer.value = null
  customerSearch.value = ''
  showCustomerDropdown.value = false
}

const createCustomer = async () => {
  creatingCustomer.value = true
  customerError.value = ''

  try {
    const response = await fetch('http://localhost:3000/graphql', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        query: `
          mutation CreateCustomer($firstName: String!, $lastName: String!, $email: String!, $mobile: String!) {
            createCustomer(firstName: $firstName, lastName: $lastName, email: $email, mobile: $mobile) {
              id
              firstName
              lastName
              email
              mobile
            }
          }
        `,
        variables: {
          firstName: newCustomer.value.firstName,
          lastName: newCustomer.value.lastName,
          email: newCustomer.value.email,
          mobile: newCustomer.value.mobile,
        },
      }),
    })

    const data = await response.json()

    if (data.errors) {
      customerError.value = data.errors[0].message
    } else {
      // Select the new customer
      selectCustomer(data.data.createCustomer)

      // Reset form
      newCustomer.value = { firstName: '', lastName: '', email: '', mobile: '' }
      customerError.value = ''

      console.log('Customer created successfully!')
    }
  } catch (err) {
    customerError.value = `Network error: ${err}`
  } finally {
    creatingCustomer.value = false
  }
}

// Cart functions
const addToCart = (product: Product) => {
  const existingItem = cartItems.value.find(item => item.product.id === product.id)

  if (existingItem) {
    if (existingItem.quantity < product.stockQuantity) {
      existingItem.quantity += 1
    }
  } else {
    cartItems.value.push({
      product,
      quantity: 1
    })
  }
}

const removeFromCart = (productId: string) => {
  cartItems.value = cartItems.value.filter(item => item.product.id !== productId)
}

const updateQuantity = (productId: string, newQuantity: number) => {
  const item = cartItems.value.find(item => item.product.id === productId)
  if (item && newQuantity > 0 && newQuantity <= item.product.stockQuantity) {
    item.quantity = newQuantity
  }
}

const clearCart = () => {
  cartItems.value = []
}

// Reset entire order workflow
const resetOrder = () => {
  clearCart()
  clearCustomer()
  currentStep.value = 'customer'
  orderType.value = 'in-store'
  shippingMethod.value = 'standard'
  paymentMethod.value = 'cash'
  deliveryInfo.value = {
    fullName: '',
    address: '',
    city: '',
    postalCode: '',
    phone: '',
    instructions: ''
  }
}

// Delivery information validation for online orders
const validateDeliveryInfo = () => {
  if (orderType.value === 'in-store') return true

  const { fullName, address, city, postalCode, phone } = deliveryInfo.value
  return fullName.trim() && address.trim() && city.trim() && postalCode.trim() && phone.trim()
}

// Order creation
const createOrder = async () => {
  if (!selectedCustomer.value || cartItems.value.length === 0) return

  // Validate delivery information for online orders
  if (!validateDeliveryInfo()) {
    alert('Please fill in all required delivery information fields.')
    return
  }

  creatingOrder.value = true

  try {
    const orderItems = cartItems.value.map(item => ({
      productId: item.product.id,
      quantity: item.quantity,
      unitPrice: item.product.price
    }))

    const response = await fetch('http://localhost:3000/graphql', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        query: `
          mutation CreateOrder(
            $customerId: ID!,
            $items: [OrderItemInput!]!,
            $orderType: String!,
            $shippingMethod: String,
            $paymentMethod: String!,
            $total: Float!,
            $deliveryAddress: String,
            $deliveryNotes: String
          ) {
            createOrder(
              customerId: $customerId,
              items: $items,
              orderType: $orderType,
              shippingMethod: $shippingMethod,
              paymentMethod: $paymentMethod,
              total: $total,
              deliveryAddress: $deliveryAddress,
              deliveryNotes: $deliveryNotes
            ) {
              id
              referenceNumber
              status
              total
              createdAt
              deliveryAddress
              deliveryNotes
            }
          }
        `,
        variables: {
          customerId: selectedCustomer.value.id,
          items: orderItems,
          orderType: orderType.value,
          shippingMethod: orderType.value === 'online' ? shippingMethod.value : null,
          paymentMethod: paymentMethod.value,
          total: total.value,
          deliveryAddress: orderType.value === 'online' ?
            `${deliveryInfo.value.fullName}\n${deliveryInfo.value.address}\n${deliveryInfo.value.city}, ${deliveryInfo.value.postalCode}\nPhone: ${deliveryInfo.value.phone}` : null,
          deliveryNotes: orderType.value === 'online' ? deliveryInfo.value.instructions : null,
        },
      }),
    })

    const data = await response.json()

    if (data.errors) {
      console.error('Error creating order:', data.errors[0].message)
      alert(`Error: ${data.errors[0].message}`)
    } else {
      console.log('Order created successfully:', data.data.createOrder)

      // Show success modal with order details
      successOrderData.value = {
        ...data.data.createOrder,
        customer: selectedCustomer.value,
        items: cartItems.value,
        orderType: orderType.value,
        shippingMethod: orderType.value === 'online' ? shippingMethod.value : null,
        paymentMethod: paymentMethod.value,
        deliveryInfo: orderType.value === 'online' ? deliveryInfo.value : null
      }
      showSuccessModal.value = true

      // Reset entire workflow after showing modal
      resetOrder()
    }
  } catch (err) {
    console.error('Network error:', err)
    alert('Failed to create order. Please try again.')
  } finally {
    creatingOrder.value = false
  }
}

// Data fetching
const fetchProducts = async () => {
  productsLoading.value = true

  try {
    const response = await fetch('http://localhost:3000/graphql', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        query: `
          query GetProducts {
            products {
              id
              name
              description
              price
              category {
                id
                name
                description
              }
              productType
              photoUrl
              stockQuantity
              createdAt
              updatedAt
            }
          }
        `,
      }),
    })

    const data = await response.json()

    if (data.data) {
      products.value = data.data.products
    }
  } catch (err) {
    console.error('Error fetching products:', err)
  } finally {
    productsLoading.value = false
  }
}

const fetchCategories = async () => {
  try {
    const response = await fetch('http://localhost:3000/graphql', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        query: `
          query GetCategories {
            categories {
              id
              name
              description
            }
          }
        `,
      }),
    })

    const data = await response.json()
    if (data.data) {
      categories.value = data.data.categories
    }
  } catch (err) {
    console.error('Error fetching categories:', err)
  }
}

// Initialize data on mount
onMounted(() => {
  fetchProducts()
  fetchCategories()
})

// Prevent TypeScript warnings for template-only functions
void filteredProducts
void searchCustomers
void createCustomer
void addToCart
void removeFromCart
void updateQuantity
void clearCart
void resetOrder
void createOrder
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Step Progress Bar -->
    <div class="bg-white shadow-sm border-b">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="py-4">
          <div class="flex items-center justify-between">
            <h1 class="text-2xl font-bold text-gray-900">Create Order</h1>

            <!-- Order Type Toggle -->
            <div class="flex space-x-4">
              <button
                @click="orderType = 'in-store'"
                :class="[
                  'px-4 py-2 rounded-md text-sm font-medium transition-colors',
                  orderType === 'in-store'
                    ? 'bg-blue-100 text-blue-700'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                ]"
              >
                In-Store
              </button>
              <button
                @click="orderType = 'online'"
                :class="[
                  'px-4 py-2 rounded-md text-sm font-medium transition-colors',
                  orderType === 'online'
                    ? 'bg-blue-100 text-blue-700'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                ]"
              >
                Online
              </button>
            </div>
          </div>

          <!-- Progress Steps -->
          <div class="mt-6">
            <nav aria-label="Progress">
              <ol class="flex items-center">
                <li class="relative pr-8 sm:pr-20">
                  <div class="absolute inset-0 flex items-center" aria-hidden="true">
                    <div class="h-0.5 w-full bg-gray-200"></div>
                  </div>
                  <div class="relative flex h-8 w-8 items-center justify-center rounded-full bg-blue-600 hover:bg-blue-900">
                    <span class="text-sm font-medium text-white">1</span>
                  </div>
                  <div class="mt-2 text-sm font-medium text-gray-900">Select Customer</div>
                </li>

                <li class="relative pr-8 sm:pr-20">
                  <div class="absolute inset-0 flex items-center" aria-hidden="true">
                    <div class="h-0.5 w-full bg-gray-200"></div>
                  </div>
                  <div :class="[
                    'relative flex h-8 w-8 items-center justify-center rounded-full transition-colors',
                    currentStep === 'products' || currentStep === 'checkout'
                      ? 'bg-blue-600 hover:bg-blue-900'
                      : 'bg-white border-2 border-gray-300'
                  ]">
                    <span :class="[
                      'text-sm font-medium',
                      currentStep === 'products' || currentStep === 'checkout'
                        ? 'text-white'
                        : 'text-gray-500'
                    ]">2</span>
                  </div>
                  <div :class="[
                    'mt-2 text-sm font-medium',
                    currentStep === 'products' || currentStep === 'checkout'
                      ? 'text-gray-900'
                      : 'text-gray-500'
                  ]">Add Products</div>
                </li>

                <li class="relative">
                  <div :class="[
                    'relative flex h-8 w-8 items-center justify-center rounded-full transition-colors',
                    currentStep === 'checkout'
                      ? 'bg-blue-600 hover:bg-blue-900'
                      : 'bg-white border-2 border-gray-300'
                  ]">
                    <span :class="[
                      'text-sm font-medium',
                      currentStep === 'checkout'
                        ? 'text-white'
                        : 'text-gray-500'
                    ]">3</span>
                  </div>
                  <div :class="[
                    'mt-2 text-sm font-medium',
                    currentStep === 'checkout'
                      ? 'text-gray-900'
                      : 'text-gray-500'
                  ]">Checkout</div>
                </li>
              </ol>
            </nav>
          </div>
        </div>
      </div>
    </div>

    <!-- Step Content -->
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">

      <!-- Step 1: Customer Selection -->
      <div v-if="currentStep === 'customer'" class="max-w-2xl mx-auto">
        <div class="bg-white rounded-lg shadow-sm border p-8">
          <h2 class="text-xl font-semibold text-gray-900 mb-6">Select Customer</h2>

          <div class="space-y-6">
            <!-- Customer Search -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Search Existing Customer</label>
              <div class="relative">
                <input
                  v-model="customerSearch"
                  @input="searchCustomers"
                  @focus="searchCustomers"
                  type="text"
                  placeholder="Search customer by email..."
                  class="w-full px-3 py-3 border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                />
                <div class="absolute right-3 top-3 flex space-x-2">
                  <button
                    v-if="selectedCustomer"
                    @click="clearCustomer"
                    class="text-gray-400 hover:text-gray-600"
                  >
                    ✕
                  </button>
                </div>

                <!-- Customer Search Dropdown -->
                <div
                  v-if="showCustomerDropdown && customerSearchResults.length > 0"
                  class="absolute z-10 mt-1 w-full bg-white border border-gray-300 rounded-md shadow-lg max-h-60 overflow-auto"
                >
                  <button
                    v-for="customer in customerSearchResults"
                    :key="customer.id"
                    @click="selectCustomer(customer)"
                    class="w-full px-4 py-3 text-left hover:bg-gray-50 focus:bg-gray-50 focus:outline-none border-b border-gray-100 last:border-b-0"
                  >
                    <div class="font-medium">{{ customer.email }}</div>
                    <div class="text-sm text-gray-500">{{ customer.mobile || 'No mobile' }}</div>
                  </button>
                </div>
              </div>
              <div v-if="selectedCustomer" class="mt-3 p-3 bg-green-50 border border-green-200 rounded-md">
                <div class="flex items-center">
                  <div class="text-sm text-green-600">
                    ✓ <strong>{{ selectedCustomer.email }}</strong>
                  </div>
                </div>
                <div v-if="selectedCustomer.mobile" class="text-sm text-gray-600 mt-1">
                  Mobile: {{ selectedCustomer.mobile }}
                </div>
              </div>
            </div>

            <!-- OR Divider -->
            <div class="relative">
              <div class="absolute inset-0 flex items-center">
                <div class="w-full border-t border-gray-300"></div>
              </div>
              <div class="relative flex justify-center text-sm">
                <span class="px-2 bg-white text-gray-500">or</span>
              </div>
            </div>

            <!-- Create New Customer -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Create New Customer</label>
              <div class="space-y-4">
                <div>
                  <input
                    v-model="newCustomer.firstName"
                    type="text"
                    placeholder="First name *"
                    class="w-full px-3 py-3 border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
                <div>
                  <input
                    v-model="newCustomer.lastName"
                    type="text"
                    placeholder="Last name *"
                    class="w-full px-3 py-3 border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
                <div>
                  <input
                    v-model="newCustomer.email"
                    type="email"
                    placeholder="Email address *"
                    class="w-full px-3 py-3 border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
                <div>
                  <input
                    v-model="newCustomer.mobile"
                    type="tel"
                    placeholder="Mobile number *"
                    class="w-full px-3 py-3 border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>

                <button
                  @click="createCustomer"
                  :disabled="!newCustomer.firstName || !newCustomer.lastName || !newCustomer.email || !newCustomer.mobile || creatingCustomer"
                  :class="[
                    'w-full px-4 py-3 rounded-md font-medium transition-colors',
                    !newCustomer.firstName || !newCustomer.lastName || !newCustomer.email || !newCustomer.mobile || creatingCustomer
                      ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                      : 'bg-blue-600 text-white hover:bg-blue-700'
                  ]"
                >
                  <span v-if="creatingCustomer">Creating Customer...</span>
                  <span v-else>Create New Customer</span>
                </button>

                <div v-if="customerError" class="text-sm text-red-600 bg-red-50 border border-red-200 rounded-md p-3">
                  {{ customerError }}
                </div>
              </div>
            </div>
          </div>

          <!-- Continue Button -->
          <div class="mt-8 pt-6 border-t">
            <button
              @click="currentStep = 'products'"
              :disabled="!selectedCustomer"
              :class="[
                'w-full px-6 py-3 rounded-md font-medium transition-colors',
                !selectedCustomer
                  ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                  : 'bg-green-600 text-white hover:bg-green-700'
              ]"
            >
              Continue to Add Products
            </button>
          </div>
        </div>
      </div>

      <!-- Step 2: Product Selection -->
      <div v-if="currentStep === 'products'" class="h-screen flex overflow-hidden">
        <!-- Left Section: Products -->
        <div class="flex-1 flex flex-col mr-4">
          <!-- Header Section - Fixed -->
          <div class="flex-shrink-0 bg-white shadow-sm border rounded-lg mb-4 p-6">
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-xl font-semibold text-gray-900">Add Products to Order</h2>
              <button
                @click="currentStep = 'customer'"
                class="px-4 py-2 text-sm text-gray-600 hover:text-gray-800 border border-gray-300 rounded-md hover:bg-gray-50"
              >
                ← Back to Customer
              </button>
            </div>

            <!-- Selected Customer Info -->
            <div class="mb-4 p-3 bg-blue-50 border border-blue-200 rounded-md">
              <div class="text-sm text-blue-800">
                <strong>Customer:</strong> {{ selectedCustomer?.email }}
                <span v-if="selectedCustomer?.mobile" class="ml-4">
                  <strong>Mobile:</strong> {{ selectedCustomer.mobile }}
                </span>
              </div>
            </div>

            <!-- Product Filters -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Search Products</label>
                <input
                  v-model="productSearch"
                  type="text"
                  placeholder="Search products..."
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Filter by Category</label>
                <div class="flex flex-wrap gap-2">
                  <button
                    @click="selectedCategory = ''"
                    :class="[
                      'px-4 py-2 rounded-full text-sm font-medium transition-colors',
                      selectedCategory === ''
                        ? 'bg-blue-600 text-white'
                        : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                    ]"
                  >
                    All
                  </button>
                  <button
                    v-for="category in categories"
                    :key="category.id"
                    @click="selectedCategory = category.id"
                    :class="[
                      'px-4 py-2 rounded-full text-sm font-medium transition-colors',
                      selectedCategory === category.id
                        ? 'bg-blue-600 text-white'
                        : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                    ]"
                  >
                    {{ category.name }}
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Products Grid - Scrollable -->
          <div class="flex-1 min-h-0 overflow-y-auto">
            <div class="bg-white rounded-lg shadow-sm border p-6">
              <div v-if="productsLoading" class="flex justify-center py-8">
                <div class="text-gray-500">Loading products...</div>
              </div>

              <div v-else-if="filteredProducts.length === 0" class="text-center py-8">
                <div class="text-gray-500">No products found</div>
              </div>

              <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                <div
                  v-for="product in filteredProducts"
                  :key="product.id"
                  class="border border-gray-200 rounded-lg overflow-hidden hover:shadow-md transition-shadow"
                >
                  <div
                    v-if="product.photoUrl"
                    class="h-48 bg-gray-200 bg-cover bg-center"
                    :style="{ backgroundImage: `url(${product.photoUrl})` }"
                  ></div>
                  <div v-else class="h-48 bg-gray-200 flex items-center justify-center">
                    <span class="text-gray-400">No Image</span>
                  </div>

                  <div class="p-4">
                    <h3 class="font-medium text-gray-900 mb-1">{{ product.name }}</h3>
                    <p class="text-sm text-gray-600 mb-2 line-clamp-2">{{ product.description }}</p>
                    <div class="flex items-center justify-between mb-2">
                      <span class="text-lg font-semibold text-gray-900">₱{{ formatPrice(product.price) }}</span>
                      <span class="text-sm text-gray-500">Stock: {{ formatNumberWithCommas(product.stockQuantity.toString()) }}</span>
                    </div>
                    <div class="mb-3">
                      <span class="inline-block px-2 py-1 text-xs bg-gray-100 text-gray-800 rounded">
                        {{ product.category.name }}
                      </span>
                      <span v-if="product.productType" class="inline-block ml-1 px-2 py-1 text-xs bg-blue-100 text-blue-800 rounded">
                        {{ product.productType }}
                      </span>
                    </div>
                    <button
                      @click="addToCart(product)"
                      :disabled="product.stockQuantity === 0"
                      :class="[
                        'w-full px-4 py-2 rounded-md text-sm font-medium transition-colors',
                        product.stockQuantity === 0
                          ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                          : 'bg-blue-600 text-white hover:bg-blue-700'
                      ]"
                    >
                      <span v-if="product.stockQuantity === 0">Out of Stock</span>
                      <span v-else>Add to Cart</span>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Right Section: Cart Summary -->
        <div class="w-96 bg-white shadow-lg border rounded-lg flex flex-col">
          <!-- Cart Header - Fixed -->
          <div class="flex-shrink-0 px-6 py-4 border-b">
            <h3 class="text-xl font-semibold text-gray-900">Order Summary</h3>
            <div class="mt-2 text-sm text-gray-600">
              {{ cartItems.length }} item{{ cartItems.length !== 1 ? 's' : '' }}
            </div>
          </div>

          <!-- Cart Items - Scrollable -->
          <div class="flex-1 min-h-0 overflow-y-auto px-6 py-4">
            <div v-if="cartItems.length === 0" class="text-center py-8">
              <div class="text-gray-500">Cart is empty</div>
              <div class="text-sm text-gray-400 mt-2">Add products to continue</div>
            </div>

            <div v-else class="space-y-4">
              <div
                v-for="item in cartItems"
                :key="item.product.id"
                class="flex items-center space-x-3 py-3 border-b border-gray-100"
              >
                <div
                  class="w-12 h-12 bg-gray-200 rounded flex-shrink-0 bg-cover bg-center"
                  :style="item.product.photoUrl ? { backgroundImage: `url(${item.product.photoUrl})` } : {}"
                >
                  <div v-if="!item.product.photoUrl" class="w-full h-full flex items-center justify-center text-xs text-gray-400">
                    IMG
                  </div>
                </div>

                <div class="flex-1 min-w-0">
                  <h4 class="text-sm font-medium text-gray-900 truncate">{{ item.product.name }}</h4>
                  <p class="text-sm text-gray-600">₱{{ formatPrice(item.product.price) }}</p>
                </div>

                <div class="flex items-center space-x-2">
                  <button
                    @click="updateQuantity(item.product.id, item.quantity - 1)"
                    :disabled="item.quantity <= 1"
                    class="w-6 h-6 rounded-full border border-gray-300 flex items-center justify-center text-sm disabled:opacity-50"
                  >
                    -
                  </button>
                  <span class="text-sm font-medium w-8 text-center">{{ item.quantity }}</span>
                  <button
                    @click="updateQuantity(item.product.id, item.quantity + 1)"
                    :disabled="item.quantity >= item.product.stockQuantity"
                    class="w-6 h-6 rounded-full border border-gray-300 flex items-center justify-center text-sm disabled:opacity-50"
                  >
                    +
                  </button>
                </div>

                <button
                  @click="removeFromCart(item.product.id)"
                  class="text-red-600 hover:text-red-800 ml-2"
                >
                  ✕
                </button>
              </div>
            </div>
          </div>

          <!-- Total and Actions - Fixed -->
          <div class="flex-shrink-0 border-t px-6 py-4 space-y-4">
            <div class="flex justify-between text-lg font-semibold">
              <span>Subtotal:</span>
              <span>₱{{ formatPrice(subtotal) }}</span>
            </div>

            <div class="space-y-2">
              <button
                @click="currentStep = 'checkout'"
                :disabled="cartItems.length === 0"
                :class="[
                  'w-full px-4 py-3 rounded-md font-medium transition-colors',
                  cartItems.length === 0
                    ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                    : 'bg-green-600 text-white hover:bg-green-700'
                ]"
              >
                Continue to Checkout
              </button>

              <button
                @click="clearCart"
                :disabled="cartItems.length === 0"
                class="w-full px-4 py-2 bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200 disabled:opacity-50"
              >
                Clear Cart
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Step 3: Checkout -->
      <div v-if="currentStep === 'checkout'" class="max-w-4xl mx-auto">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">

          <!-- Left: Order Details -->
          <div class="bg-white rounded-lg shadow-sm border p-6">
            <div class="flex items-center justify-between mb-6">
              <h2 class="text-xl font-semibold text-gray-900">Order Details</h2>
              <button
                @click="currentStep = 'products'"
                class="px-4 py-2 text-sm text-gray-600 hover:text-gray-800 border border-gray-300 rounded-md hover:bg-gray-50"
              >
                ← Back to Products
              </button>
            </div>

            <!-- Customer Info -->
            <div class="mb-6 p-4 bg-blue-50 border border-blue-200 rounded-md">
              <h3 class="text-sm font-medium text-blue-900 mb-2">Customer Information</h3>
              <div class="text-sm text-blue-800">
                <div><strong>Email:</strong> {{ selectedCustomer?.email }}</div>
                <div v-if="selectedCustomer?.mobile"><strong>Mobile:</strong> {{ selectedCustomer.mobile }}</div>
              </div>
            </div>

            <!-- Order Items -->
            <div class="mb-6">
              <h3 class="text-sm font-medium text-gray-900 mb-3">Order Items</h3>
              <div class="space-y-3">
                <div
                  v-for="item in cartItems"
                  :key="item.product.id"
                  class="flex items-center justify-between py-2 border-b border-gray-100"
                >
                  <div class="flex items-center space-x-3">
                    <div
                      class="w-10 h-10 bg-gray-200 rounded bg-cover bg-center flex-shrink-0"
                      :style="item.product.photoUrl ? { backgroundImage: `url(${item.product.photoUrl})` } : {}"
                    >
                      <div v-if="!item.product.photoUrl" class="w-full h-full flex items-center justify-center text-xs text-gray-400">
                        IMG
                      </div>
                    </div>
                    <div>
                      <div class="text-sm font-medium text-gray-900">{{ item.product.name }}</div>
                      <div class="text-sm text-gray-500">₱{{ formatPrice(item.product.price) }} × {{ item.quantity }}</div>
                    </div>
                  </div>
                  <div class="text-sm font-medium text-gray-900">
                    ₱{{ formatPrice(item.product.price * item.quantity) }}
                  </div>
                </div>
              </div>
            </div>

            <!-- Payment & Shipping -->
            <div class="space-y-4">
              <!-- Delivery Information (only for online orders) -->
              <div v-if="orderType === 'online'" class="border border-gray-200 rounded-lg p-4 bg-gray-50">
                <h3 class="text-sm font-medium text-gray-900 mb-3">Delivery Information</h3>
                <div class="space-y-3">
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                    <div>
                      <label class="block text-xs font-medium text-gray-700 mb-1">Full Name *</label>
                      <input
                        v-model="deliveryInfo.fullName"
                        type="text"
                        placeholder="Recipient's full name"
                        class="w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                      />
                    </div>
                    <div>
                      <label class="block text-xs font-medium text-gray-700 mb-1">Phone Number *</label>
                      <input
                        v-model="deliveryInfo.phone"
                        type="tel"
                        placeholder="Contact number"
                        class="w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                      />
                    </div>
                  </div>

                  <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1">Address *</label>
                    <input
                      v-model="deliveryInfo.address"
                      type="text"
                      placeholder="Street address, building, unit number"
                      class="w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                    />
                  </div>

                  <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                    <div>
                      <label class="block text-xs font-medium text-gray-700 mb-1">City *</label>
                      <input
                        v-model="deliveryInfo.city"
                        type="text"
                        placeholder="City"
                        class="w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                      />
                    </div>
                    <div>
                      <label class="block text-xs font-medium text-gray-700 mb-1">Postal Code *</label>
                      <input
                        v-model="deliveryInfo.postalCode"
                        type="text"
                        placeholder="Postal code"
                        class="w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                      />
                    </div>
                  </div>

                  <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1">Delivery Instructions (Optional)</label>
                    <textarea
                      v-model="deliveryInfo.instructions"
                      placeholder="Special delivery instructions, landmarks, etc."
                      rows="2"
                      class="w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                    ></textarea>
                  </div>
                </div>
              </div>

              <!-- Shipping Method (only for online orders) -->
              <div v-if="orderType === 'online'">
                <label class="block text-sm font-medium text-gray-700 mb-2">Shipping Method</label>
                <select
                  v-model="shippingMethod"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="standard">Standard Shipping (₱250.00)</option>
                  <option value="express">Express Shipping (₱750.00)</option>
                  <option value="overnight">Overnight Shipping (₱1,250.00)</option>
                </select>
              </div>

              <!-- Payment Method -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Payment Method</label>
                <select
                  v-model="paymentMethod"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="cash">Cash</option>
                  <option value="card">Credit Card</option>
                  <option value="digital">Digital Wallet</option>
                </select>
              </div>
            </div>
          </div>

          <!-- Right: Order Summary & Actions -->
          <div class="bg-white rounded-lg shadow-sm border p-6">
            <h2 class="text-xl font-semibold text-gray-900 mb-6">Order Summary</h2>

            <!-- Order Totals -->
            <div class="space-y-3 mb-6">
              <div class="flex justify-between text-sm">
                <span>Subtotal:</span>
                <span>₱{{ formatPrice(subtotal) }}</span>
              </div>
              <div v-if="shippingCost > 0" class="flex justify-between text-sm">
                <span>Shipping:</span>
                <span>₱{{ formatPrice(shippingCost) }}</span>
              </div>
              <div class="flex justify-between text-lg font-semibold border-t pt-3">
                <span>Total:</span>
                <span>₱{{ formatPrice(total) }}</span>
              </div>
            </div>

            <!-- Action Buttons -->
            <div class="space-y-3">
              <button
                @click="createOrder"
                :disabled="cartItems.length === 0 || creatingOrder"
                :class="[
                  'w-full px-6 py-3 rounded-md font-medium transition-colors',
                  cartItems.length === 0 || creatingOrder
                    ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                    : 'bg-green-600 text-white hover:bg-green-700'
                ]"
              >
                <span v-if="creatingOrder">Creating Order...</span>
                <span v-else>Create Order (₱{{ formatPrice(total) }})</span>
              </button>

              <button
                @click="resetOrder"
                class="w-full px-4 py-2 bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200"
              >
                Start Over
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- Order Success Modal -->
  <div
    v-if="showSuccessModal"
    class="fixed inset-0 bg-gray-600 bg-opacity-50 flex items-center justify-center z-50"
    @click.self="showSuccessModal = false"
  >
    <div class="bg-white rounded-lg shadow-xl max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
      <!-- Modal Header -->
      <div class="bg-green-600 text-white px-6 py-4 rounded-t-lg">
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-3">
            <div class="w-8 h-8 bg-green-500 rounded-full flex items-center justify-center">
              <span class="text-white font-bold text-lg">✓</span>
            </div>
            <div>
              <h2 class="text-xl font-bold">Order Created Successfully!</h2>
              <p class="text-green-100 text-sm">Reference: #{{ successOrderData?.referenceNumber }}</p>
            </div>
          </div>
          <button
            @click="showSuccessModal = false"
            class="text-white hover:text-gray-200 text-2xl font-bold w-8 h-8 flex items-center justify-center"
          >
            ×
          </button>
        </div>
      </div>

      <!-- Modal Content -->
      <div class="p-6" v-if="successOrderData">
        <!-- Order Summary -->
        <div class="mb-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Order Summary</h3>
          <div class="bg-gray-50 rounded-lg p-4">
            <div class="grid grid-cols-2 gap-4 text-sm">
              <div>
                <span class="font-medium text-gray-700">Order ID:</span>
                <span class="ml-2">{{ successOrderData.id }}</span>
              </div>
              <div>
                <span class="font-medium text-gray-700">Reference:</span>
                <span class="ml-2">#{{ successOrderData.referenceNumber }}</span>
              </div>
              <div>
                <span class="font-medium text-gray-700">Status:</span>
                <span class="ml-2 px-2 py-1 bg-yellow-100 text-yellow-800 rounded text-xs">{{ successOrderData.status }}</span>
              </div>
              <div>
                <span class="font-medium text-gray-700">Order Type:</span>
                <span class="ml-2 capitalize">{{ successOrderData.orderType }}</span>
              </div>
              <div>
                <span class="font-medium text-gray-700">Payment Method:</span>
                <span class="ml-2 capitalize">{{ successOrderData.paymentMethod }}</span>
              </div>
              <div v-if="successOrderData.shippingMethod">
                <span class="font-medium text-gray-700">Shipping:</span>
                <span class="ml-2 capitalize">{{ successOrderData.shippingMethod }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Customer Information -->
        <div class="mb-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Customer Information</h3>
          <div class="bg-blue-50 rounded-lg p-4">
            <div class="text-sm">
              <div class="mb-2">
                <span class="font-medium text-blue-900">Email:</span>
                <span class="ml-2">{{ successOrderData.customer?.email }}</span>
              </div>
              <div v-if="successOrderData.customer?.mobile">
                <span class="font-medium text-blue-900">Mobile:</span>
                <span class="ml-2">{{ successOrderData.customer.mobile }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Delivery Information (for online orders) -->
        <div v-if="successOrderData.orderType === 'online' && successOrderData.deliveryInfo" class="mb-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Delivery Information</h3>
          <div class="bg-orange-50 rounded-lg p-4">
            <div class="text-sm space-y-2">
              <div>
                <span class="font-medium text-orange-900">Recipient:</span>
                <span class="ml-2">{{ successOrderData.deliveryInfo.fullName }}</span>
              </div>
              <div>
                <span class="font-medium text-orange-900">Phone:</span>
                <span class="ml-2">{{ successOrderData.deliveryInfo.phone }}</span>
              </div>
              <div>
                <span class="font-medium text-orange-900">Address:</span>
                <div class="ml-2 mt-1">
                  <div>{{ successOrderData.deliveryInfo.address }}</div>
                  <div>{{ successOrderData.deliveryInfo.city }}, {{ successOrderData.deliveryInfo.postalCode }}</div>
                </div>
              </div>
              <div v-if="successOrderData.deliveryInfo.instructions">
                <span class="font-medium text-orange-900">Instructions:</span>
                <div class="ml-2 mt-1">{{ successOrderData.deliveryInfo.instructions }}</div>
              </div>
            </div>
          </div>
        </div>

        <!-- Order Items -->
        <div class="mb-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Order Items</h3>
          <div class="space-y-3">
            <div
              v-for="item in successOrderData.items"
              :key="item.product.id"
              class="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
            >
              <div class="flex items-center space-x-3">
                <div
                  class="w-12 h-12 bg-gray-200 rounded bg-cover bg-center flex-shrink-0"
                  :style="item.product.photoUrl ? { backgroundImage: `url(${item.product.photoUrl})` } : {}"
                >
                  <div v-if="!item.product.photoUrl" class="w-full h-full flex items-center justify-center text-xs text-gray-400">
                    IMG
                  </div>
                </div>
                <div>
                  <h4 class="text-sm font-medium text-gray-900">{{ item.product.name }}</h4>
                  <p class="text-sm text-gray-600">₱{{ formatPrice(item.product.price) }} × {{ item.quantity }}</p>
                </div>
              </div>
              <div class="text-sm font-medium text-gray-900">
                ₱{{ formatPrice(item.product.price * item.quantity) }}
              </div>
            </div>
          </div>
        </div>

        <!-- Total -->
        <div class="border-t pt-4 mb-6">
          <div class="bg-green-50 rounded-lg p-4">
            <div class="flex justify-between items-center">
              <span class="text-xl font-bold text-green-900">Total Amount:</span>
              <span class="text-2xl font-bold text-green-900">₱{{ formatPrice(successOrderData.total) }}</span>
            </div>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="flex space-x-4">
          <button
            @click="showSuccessModal = false"
            class="flex-1 px-6 py-3 bg-green-600 text-white rounded-md hover:bg-green-700 font-medium transition-colors"
          >
            Create Another Order
          </button>
          <button
            @click="$router.push('/orders')"
            class="flex-1 px-6 py-3 bg-blue-600 text-white rounded-md hover:bg-blue-700 font-medium transition-colors"
          >
            View All Orders
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
