<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useQuery, useMutation } from '@vue/apollo-composable'
import { gql } from '@apollo/client/core'

const GET_ORDERS = gql`
  query GetOrders {
    orders {
      id
      referenceNumber
      customer {
        id
        email
        mobile
        fullName
      }
      orderItems {
        quantity
        product {
          id
          name
          price
        }
      }
      status
      total
      orderType
      shippingMethod
      paymentMethod
      deliveryAddress
      deliveryNotes
      createdAt
      updatedAt
    }
  }
`

const UPDATE_ORDER_STATUS = gql`
  mutation UpdateOrderStatus($id: ID!, $status: String!) {
    updateOrderStatus(id: $id, status: $status) {
      id
      referenceNumber
      status
      updatedAt
    }
  }
`

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

interface Customer {
  id: string
  email: string
  mobile: string
  fullName: string
}

interface Product {
  id: string
  name: string
  price: number
}

interface OrderItem {
  quantity: number
  product: Product
}

interface Order {
  id: string
  referenceNumber: string
  customer: Customer
  orderItems: OrderItem[]
  status: 'pending' | 'confirmed' | 'completed' | 'cancelled'
  total: number
  orderType: string | null
  shippingMethod: string | null
  paymentMethod: string | null
  deliveryAddress: string | null
  deliveryNotes: string | null
  createdAt: string
  updatedAt: string
}

// Data refs
const selectedOrder = ref<Order | null>(null)

// Apollo composables
const {
  result: ordersResult,
  loading,
  error: ordersError,
  refetch: refetchOrders,
} = useQuery(GET_ORDERS)
const { mutate: updateStatus, loading: updatingStatus } =
  useMutation(UPDATE_ORDER_STATUS)

// Filters
const activeTab = ref('all') // 'all', 'pending', 'confirmed', 'completed', 'cancelled'
const searchQuery = ref('')

// Computed properties
const orders = computed(() => ordersResult.value?.orders || [])

const error = computed(() => ordersError.value?.message || '')

const filteredOrders = computed(() => {
  let filtered = orders.value

  // Tab filter
  if (activeTab.value !== 'all') {
    filtered = filtered.filter((order: Order) => order.status === activeTab.value)
  }

  // Search filter
  if (searchQuery.value) {
    const search = searchQuery.value.toLowerCase()
    filtered = filtered.filter(
      (order: Order) =>
        order.referenceNumber.toLowerCase().includes(search) ||
        order.customer.email.toLowerCase().includes(search) ||
        order.customer.mobile?.toLowerCase().includes(search)
    )
  }

  // Sort by creation date (newest first)
  return filtered.sort(
    (a: Order, b: Order) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
  )
})

// Tab counts
const tabCounts = computed(() => {
  const counts = {
    all: orders.value.length,
    pending: orders.value.filter((o: Order) => o.status === 'pending').length,
    confirmed: orders.value.filter((o: Order) => o.status === 'confirmed').length,
    completed: orders.value.filter((o: Order) => o.status === 'completed').length,
    cancelled: orders.value.filter((o: Order) => o.status === 'cancelled').length,
  }
  return counts
})

// Tab management functions
const setActiveTab = (tab: string) => {
  activeTab.value = tab
}

// Helper functions
const formatDate = (dateString: string) => {
  const date = new Date(dateString)
  return (
    date.toLocaleDateString() +
    ' ' +
    date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  )
}

const getStatusBadgeClass = (status: string) => {
  switch (status) {
    case 'pending':
      return 'bg-yellow-100 text-yellow-800'
    case 'confirmed':
      return 'bg-blue-100 text-blue-800'
    case 'completed':
      return 'bg-green-100 text-green-800'
    case 'cancelled':
      return 'bg-red-100 text-red-800'
    default:
      return 'bg-gray-100 text-gray-800'
  }
}

// Order management functions
const selectOrder = (order: Order) => {
  // Deep clone to avoid reactive readonly issues
  selectedOrder.value = JSON.parse(JSON.stringify(order))
}

const clearSelection = () => {
  selectedOrder.value = null
}

const updateOrderStatus = async (
  newStatus: 'pending' | 'confirmed' | 'completed' | 'cancelled'
) => {
  if (!selectedOrder.value) return

  // Confirmation dialog
  const statusMessages = {
    pending: 'Mark this order as Pending',
    confirmed: 'Confirm this order',
    completed: 'Mark this order as Completed',
    cancelled: 'Cancel this order'
  }

  const confirmMessage = `${statusMessages[newStatus]}?\n\nOrder: ${selectedOrder.value.referenceNumber}\nCustomer: ${selectedOrder.value.customer.fullName}`

  if (!confirm(confirmMessage)) {
    return
  }

  try {
    const result = await updateStatus({
      id: selectedOrder.value.id,
      status: newStatus,
    })

    if (result?.data?.updateOrderStatus) {
      console.log(`Order status updated to ${newStatus}`)

      // Refresh the orders list to get updated data from the server
      await fetchOrders()

      // Create a fresh copy of the updated order from server data to avoid readonly issues
      const updatedOrderFromServer = orders.value.find((o: Order) => o.id === selectedOrder.value!.id)
      if (updatedOrderFromServer) {
        // Deep clone to avoid reactive readonly issues
        selectedOrder.value = JSON.parse(JSON.stringify(updatedOrderFromServer))
      }
    }
  } catch (err: any) {
    console.error('Error updating order status:', err.message)
    alert(`Failed to update order status. Error: ${err.message}`)
  }
}

// Data fetching
const fetchOrders = async () => {
  await refetchOrders()
}

// Initialize data on mount
onMounted(() => {
  fetchOrders()
})

// Prevent TypeScript warnings for template-only functions
void filteredOrders
void formatDate
void getStatusBadgeClass
void selectOrder
void clearSelection
void updateOrderStatus
void fetchOrders
</script>

<template>
  <div class="flex h-screen overflow-hidden bg-gray-50">
    <!-- Left Section: Order List -->
    <div class="mr-4 flex flex-1 flex-col">
      <!-- Header Section - Fixed -->
      <div class="flex-shrink-0 border-b bg-white p-6 shadow-sm">
        <div class="mb-4 flex items-center justify-between">
          <h1 class="text-2xl font-bold text-gray-900">Order Management</h1>
          <button
            @click="fetchOrders"
            :disabled="loading"
            class="rounded-md bg-blue-600 px-4 py-2 text-white hover:bg-blue-700 disabled:opacity-50"
          >
            <span v-if="loading">Refreshing...</span>
            <span v-else>Refresh</span>
          </button>
        </div>

        <!-- Search and Tabs -->
        <div class="space-y-4">
          <!-- Search Bar -->
          <div>
            <label class="mb-2 block text-sm font-medium text-gray-700"
              >Search Orders</label
            >
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Search by order number, customer email, or mobile..."
              class="w-full rounded-md border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
          </div>

          <!-- Status Tabs -->
          <div>
            <div class="border-b border-gray-200">
              <nav class="-mb-px flex space-x-8" aria-label="Tabs">
                <button
                  @click="setActiveTab('all')"
                  :class="[
                    'whitespace-nowrap border-b-2 px-1 py-2 text-sm font-medium transition-colors',
                    activeTab === 'all'
                      ? 'border-blue-500 text-blue-600'
                      : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700',
                  ]"
                >
                  All Orders
                  <span
                    :class="[
                      'ml-2 inline-flex items-center justify-center rounded-full px-2 py-0.5 text-xs font-medium',
                      activeTab === 'all'
                        ? 'bg-blue-100 text-blue-600'
                        : 'bg-gray-100 text-gray-900',
                    ]"
                  >
                    {{ tabCounts.all }}
                  </span>
                </button>

                <button
                  @click="setActiveTab('pending')"
                  :class="[
                    'whitespace-nowrap border-b-2 px-1 py-2 text-sm font-medium transition-colors',
                    activeTab === 'pending'
                      ? 'border-yellow-500 text-yellow-600'
                      : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700',
                  ]"
                >
                  Pending
                  <span
                    :class="[
                      'ml-2 inline-flex items-center justify-center rounded-full px-2 py-0.5 text-xs font-medium',
                      activeTab === 'pending'
                        ? 'bg-yellow-100 text-yellow-600'
                        : 'bg-gray-100 text-gray-900',
                    ]"
                  >
                    {{ tabCounts.pending }}
                  </span>
                </button>

                <button
                  @click="setActiveTab('confirmed')"
                  :class="[
                    'whitespace-nowrap border-b-2 px-1 py-2 text-sm font-medium transition-colors',
                    activeTab === 'confirmed'
                      ? 'border-blue-500 text-blue-600'
                      : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700',
                  ]"
                >
                  Confirmed
                  <span
                    :class="[
                      'ml-2 inline-flex items-center justify-center rounded-full px-2 py-0.5 text-xs font-medium',
                      activeTab === 'confirmed'
                        ? 'bg-blue-100 text-blue-600'
                        : 'bg-gray-100 text-gray-900',
                    ]"
                  >
                    {{ tabCounts.confirmed }}
                  </span>
                </button>

                <button
                  @click="setActiveTab('completed')"
                  :class="[
                    'whitespace-nowrap border-b-2 px-1 py-2 text-sm font-medium transition-colors',
                    activeTab === 'completed'
                      ? 'border-green-500 text-green-600'
                      : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700',
                  ]"
                >
                  Completed
                  <span
                    :class="[
                      'ml-2 inline-flex items-center justify-center rounded-full px-2 py-0.5 text-xs font-medium',
                      activeTab === 'completed'
                        ? 'bg-green-100 text-green-600'
                        : 'bg-gray-100 text-gray-900',
                    ]"
                  >
                    {{ tabCounts.completed }}
                  </span>
                </button>

                <button
                  @click="setActiveTab('cancelled')"
                  :class="[
                    'whitespace-nowrap border-b-2 px-1 py-2 text-sm font-medium transition-colors',
                    activeTab === 'cancelled'
                      ? 'border-red-500 text-red-600'
                      : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700',
                  ]"
                >
                  Cancelled
                  <span
                    :class="[
                      'ml-2 inline-flex items-center justify-center rounded-full px-2 py-0.5 text-xs font-medium',
                      activeTab === 'cancelled'
                        ? 'bg-red-100 text-red-600'
                        : 'bg-gray-100 text-gray-900',
                    ]"
                  >
                    {{ tabCounts.cancelled }}
                  </span>
                </button>
              </nav>
            </div>
          </div>
        </div>
      </div>

      <!-- Orders List - Scrollable -->
      <div class="min-h-0 flex-1 overflow-y-auto p-6">
        <div
          v-if="loading && orders.length === 0"
          class="flex justify-center py-8"
        >
          <div class="text-gray-500">Loading orders...</div>
        </div>

        <div v-else-if="error" class="py-8 text-center">
          <div class="mb-4 text-red-600">{{ error }}</div>
          <button
            @click="fetchOrders"
            class="rounded-md bg-blue-600 px-4 py-2 text-white hover:bg-blue-700"
          >
            Try Again
          </button>
        </div>

        <div v-else-if="filteredOrders.length === 0" class="py-8 text-center">
          <div class="text-gray-500">No orders found</div>
        </div>

        <div v-else class="space-y-4">
          <div
            v-for="order in filteredOrders"
            :key="order.id"
            @click="selectOrder(order)"
            :class="[
              'cursor-pointer rounded-lg border bg-white shadow-sm transition-all hover:shadow-md',
              selectedOrder?.id === order.id
                ? 'border-blue-500 bg-blue-50'
                : 'border-gray-200',
            ]"
          >
            <div class="p-6">
              <div class="mb-4 flex items-center justify-between">
                <div>
                  <h3 class="text-lg font-semibold text-gray-900">
                    {{ order.referenceNumber }}
                  </h3>
                  <p class="text-sm text-gray-600">
                    {{ order.customer.email }}
                  </p>
                  <p v-if="order.customer.mobile" class="text-sm text-gray-600">
                    {{ order.customer.mobile }}
                  </p>
                </div>
                <div class="text-right">
                  <span
                    :class="[
                      'inline-block rounded-full px-3 py-1 text-sm font-medium',
                      getStatusBadgeClass(order.status),
                    ]"
                  >
                    {{
                      order.status.charAt(0).toUpperCase() +
                      order.status.slice(1)
                    }}
                  </span>
                  <p class="mt-1 text-lg font-semibold text-gray-900">
                    ₱{{ formatPrice(order.total) }}
                  </p>
                </div>
              </div>

              <div
                class="flex items-center justify-between text-sm text-gray-600"
              >
                <div>
                  <span class="capitalize">{{ order.orderType }}</span>
                  <span v-if="order.shippingMethod" class="ml-2"
                    >• {{ order.shippingMethod }}</span
                  >
                  <span class="ml-2">• {{ order.paymentMethod }}</span>
                </div>
                <div>
                  {{ formatDate(order.createdAt) }}
                </div>
              </div>

              <div class="mt-3 text-sm text-gray-600">
                {{ order.orderItems.length }} item{{
                  order.orderItems.length !== 1 ? 's' : ''
                }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Right Section: Order Details -->
    <div class="flex w-96 flex-col border-l bg-white shadow-lg">
      <div
        v-if="!selectedOrder"
        class="flex flex-1 items-center justify-center"
      >
        <div class="text-center text-gray-500">
          <div class="mb-2 text-lg">Select an order</div>
          <div class="text-sm">
            Choose an order from the list to view details
          </div>
        </div>
      </div>

      <div v-else class="flex h-full flex-col">
        <!-- Order Details Header - Fixed -->
        <div class="flex-shrink-0 border-b px-6 py-4">
          <div class="mb-4 flex items-center justify-between">
            <h2 class="text-xl font-semibold text-gray-900">Order Details</h2>
            <button
              @click="clearSelection"
              class="text-gray-400 hover:text-gray-600"
            >
              ✕
            </button>
          </div>

          <div class="space-y-2">
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-700"
                >Order Number:</span
              >
              <span class="text-sm text-gray-900">{{
                selectedOrder.referenceNumber
              }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-700">Status:</span>
              <span
                :class="[
                  'rounded-full px-2 py-1 text-sm',
                  getStatusBadgeClass(selectedOrder.status),
                ]"
              >
                {{
                  selectedOrder.status.charAt(0).toUpperCase() +
                  selectedOrder.status.slice(1)
                }}
              </span>
            </div>
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-700">Total:</span>
              <span class="text-sm font-semibold text-gray-900"
                >₱{{ formatPrice(selectedOrder.total) }}</span
              >
            </div>
          </div>
        </div>

        <!-- Customer Information -->
        <div class="flex-shrink-0 border-b px-6 py-4">
          <h3 class="mb-3 text-lg font-medium text-gray-900">
            Customer Information
          </h3>
          <div class="space-y-2">
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-700">Name:</span>
              <span class="text-sm text-gray-900">{{
                selectedOrder.customer.fullName
              }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-700">Email:</span>
              <span class="text-sm text-gray-900">{{
                selectedOrder.customer.email
              }}</span>
            </div>
            <div
              v-if="selectedOrder.customer.mobile"
              class="flex justify-between"
            >
              <span class="text-sm font-medium text-gray-700">Mobile:</span>
              <span class="text-sm text-gray-900">{{
                selectedOrder.customer.mobile
              }}</span>
            </div>
          </div>
        </div>

        <!-- Order Items - Scrollable -->
        <div class="min-h-0 flex-1 overflow-y-auto px-6 py-4">
          <h3 class="mb-3 text-lg font-medium text-gray-900">Order Items</h3>
          <div class="space-y-3">
            <div
              v-for="(item, index) in selectedOrder.orderItems"
              :key="index"
              class="flex items-center justify-between border-b border-gray-100 py-3"
            >
              <div class="flex-1">
                <h4 class="text-sm font-medium text-gray-900">
                  {{ item.product.name }}
                </h4>
                <p class="text-sm text-gray-600">
                  ₱{{ formatPrice(item.product.price) }} each
                </p>
              </div>
              <div class="text-right">
                <div class="text-sm font-medium text-gray-900">
                  Qty: {{ item.quantity }}
                </div>
                <div class="text-sm text-gray-600">
                  ₱{{ formatPrice(item.product.price * item.quantity) }}
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Order Management Actions - Fixed -->
        <div class="flex-shrink-0 border-t px-6 py-4">
          <div class="space-y-4">
            <div>
              <h3 class="mb-2 text-sm font-medium text-gray-700">
                Order Information
              </h3>
              <div class="space-y-1 text-sm text-gray-600">
                <div>
                  Type:
                  <span class="capitalize">{{ selectedOrder.orderType }}</span>
                </div>
                <div v-if="selectedOrder.shippingMethod">
                  Shipping: {{ selectedOrder.shippingMethod }}
                </div>
                <div>Payment: {{ selectedOrder.paymentMethod }}</div>
                <div v-if="selectedOrder.deliveryAddress">
                  <div class="font-medium text-gray-700 mt-2">Delivery Address:</div>
                  <div class="ml-2 whitespace-pre-line">{{ selectedOrder.deliveryAddress }}</div>
                </div>
                <div v-if="selectedOrder.deliveryNotes">
                  <div class="font-medium text-gray-700 mt-2">Delivery Notes:</div>
                  <div class="ml-2">{{ selectedOrder.deliveryNotes }}</div>
                </div>
                <div>Created: {{ formatDate(selectedOrder.createdAt) }}</div>
                <div>Updated: {{ formatDate(selectedOrder.updatedAt) }}</div>
              </div>
            </div>

            <div>
              <h3 class="mb-2 text-sm font-medium text-gray-700">
                Status Actions
              </h3>
              <div class="grid grid-cols-2 gap-2">
                <button
                  @click="updateOrderStatus('pending')"
                  :disabled="
                    selectedOrder.status === 'pending' || updatingStatus
                  "
                  :class="[
                    'rounded-md px-3 py-2 text-xs font-medium transition-colors',
                    selectedOrder.status === 'pending' || updatingStatus
                      ? 'cursor-not-allowed bg-gray-100 text-gray-400'
                      : 'bg-yellow-100 text-yellow-800 hover:bg-yellow-200',
                  ]"
                >
                  Pending
                </button>
                <button
                  @click="updateOrderStatus('confirmed')"
                  :disabled="
                    selectedOrder.status === 'confirmed' || updatingStatus
                  "
                  :class="[
                    'rounded-md px-3 py-2 text-xs font-medium transition-colors',
                    selectedOrder.status === 'confirmed' || updatingStatus
                      ? 'cursor-not-allowed bg-gray-100 text-gray-400'
                      : 'bg-blue-100 text-blue-800 hover:bg-blue-200',
                  ]"
                >
                  Confirm
                </button>
                <button
                  @click="updateOrderStatus('completed')"
                  :disabled="
                    selectedOrder.status === 'completed' || updatingStatus
                  "
                  :class="[
                    'rounded-md px-3 py-2 text-xs font-medium transition-colors',
                    selectedOrder.status === 'completed' || updatingStatus
                      ? 'cursor-not-allowed bg-gray-100 text-gray-400'
                      : 'bg-green-100 text-green-800 hover:bg-green-200',
                  ]"
                >
                  Complete
                </button>
                <button
                  @click="updateOrderStatus('cancelled')"
                  :disabled="
                    selectedOrder.status === 'cancelled' || updatingStatus
                  "
                  :class="[
                    'rounded-md px-3 py-2 text-xs font-medium transition-colors',
                    selectedOrder.status === 'cancelled' || updatingStatus
                      ? 'cursor-not-allowed bg-gray-100 text-gray-400'
                      : 'bg-red-100 text-red-800 hover:bg-red-200',
                  ]"
                >
                  Cancel
                </button>
              </div>
              <div
                v-if="updatingStatus"
                class="mt-2 text-center text-xs text-gray-600"
              >
                Updating status...
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
