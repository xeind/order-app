<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useQuery, useMutation, useLazyQuery } from '@vue/apollo-composable'
import { gql } from '@apollo/client/core'
import { useCartStore } from '@/stores/cart'
import { useToast } from 'vue-toastification'
import { useRoute } from 'vue-router'
import jsPDF from 'jspdf'

const toast = useToast()
const route = useRoute()

// GraphQL Queries and Mutations
const GET_ORDERS = gql`
  query GetOrders {
    orders {
      id
      referenceNumber
      customer {
        id
        firstName
        lastName
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
          photoUrl
        }
      }
      status
      total
      orderType
      shippingMethod
      paymentMethod
      createdAt
      updatedAt
    }
  }
`

const GET_PRODUCTS = gql`
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
`

const GET_CATEGORIES = gql`
  query GetCategories {
    categories {
      id
      name
      description
    }
  }
`

const SEARCH_CUSTOMERS = gql`
  query SearchCustomers($search: String!) {
    customers(search: $search) {
      id
      firstName
      lastName
      email
      mobile
      fullName
    }
  }
`

const VALIDATE_VOUCHER = gql`
  query ValidateVoucher($code: String!, $subtotal: Float!) {
    validateVoucher(code: $code, subtotal: $subtotal) {
      id
      code
      name
      discountType
      discountValue
      active
      usageLimit
      usageCount
      expiresAt
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

const CREATE_CUSTOMER = gql`
  mutation CreateCustomer(
    $firstName: String!
    $lastName: String!
    $email: String!
    $mobile: String!
  ) {
    createCustomer(
      firstName: $firstName
      lastName: $lastName
      email: $email
      mobile: $mobile
    ) {
      id
      firstName
      lastName
      email
      mobile
      fullName
    }
  }
`

const CREATE_ORDER = gql`
  mutation CreateOrder(
    $customerId: ID!
    $items: [OrderItemInput!]!
    $orderType: String!
    $shippingMethod: String
    $paymentMethod: String!
    $voucherCode: String
    $deliveryAddress: String
    $deliveryNotes: String
    $deliveryDatePreference: ISO8601DateTime
  ) {
    createOrder(
      customerId: $customerId
      items: $items
      orderType: $orderType
      shippingMethod: $shippingMethod
      paymentMethod: $paymentMethod
      voucherCode: $voucherCode
      deliveryAddress: $deliveryAddress
      deliveryNotes: $deliveryNotes
      deliveryDatePreference: $deliveryDatePreference
    ) {
      id
      referenceNumber
      status
      orderType
      paymentMethod
      shippingMethod
      subtotal
      discountAmount
      total
      deliveryAddress
      deliveryNotes
      deliveryDatePreference
      customer {
        id
        firstName
        lastName
        email
        mobile
      }
      voucher {
        code
        name
        discountType
        discountValue
      }
      createdAt
    }
  }
`

// Current view mode: 'create' or 'manage'
const currentView = ref<'create' | 'manage'>('manage')

// Workflow steps for create order - Updated to match specs (Products first, like Shopee/Lazada)
type WorkflowStep = 'products' | 'checkout'
const currentStep = ref<WorkflowStep>('products')

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

// Types
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
  firstName: string
  lastName: string
  email: string
  mobile: string
  fullName: string
}

interface CartItem {
  product: Product
  quantity: number
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
  deliveryAddress?: string | null
  deliveryNotes?: string | null
  deliveryDatePreference?: string | null
  createdAt: string
  updatedAt: string
}

// === CREATE ORDER STATE ===
// Order type
const orderType = ref<'in-store' | 'online'>('in-store')

// Customer management
const customerSearch = ref('')
const customerSearchResults = ref<Customer[]>([])
const selectedCustomer = ref<Customer | null>(null)
const showCustomerDropdown = ref(false)
const newCustomer = ref({ firstName: '', lastName: '', email: '', mobile: '' })
const customerError = ref('')

// Products (using Apollo query now)
const productSearch = ref('')
const selectedCategory = ref('')

// Cart management
const cartItems = ref<CartItem[]>([])

// Order creation
const shippingMethod = ref('standard')
const paymentMethod = ref('cash')

// Voucher functionality
const voucherCode = ref('')
const appliedVoucher = ref<any>(null)
const discountAmount = ref(0)
const voucherError = ref('')
const applyingVoucher = ref(false)

// Delivery information
const deliveryInfo = ref({
  // Required fields
  province: '',
  city: '',
  barangay: '',
  street: '',
  // Optional fields
  unit: '',
  floor: '',
  building: '',
  landmark: '',
  remarks: '',
})
const deliveryNotes = ref('')
const deliveryDatePreference = ref('')

// Customer form validation
const isCustomerFormValid = computed(() => {
  return (
    newCustomer.value.firstName.trim() !== '' &&
    newCustomer.value.lastName.trim() !== '' &&
    newCustomer.value.email.trim() !== '' &&
    newCustomer.value.mobile.trim() !== ''
  )
})

// Delivery info validation - all required fields must be filled
const isDeliveryInfoValid = computed(() => {
  return (
    deliveryInfo.value.province.trim() !== '' &&
    deliveryInfo.value.city.trim() !== '' &&
    deliveryInfo.value.barangay.trim() !== '' &&
    deliveryInfo.value.street.trim() !== ''
  )
})

// Stock validation - check if any cart items exceed available stock
const hasStockIssues = computed(() => {
  return cartItems.value.some(item => {
    const currentProduct = products.value.find((p: any) => p.id === item.product.id)
    return currentProduct ? item.quantity > currentProduct.stockQuantity : false
  })
})

// Order Success Popup State
const showSuccessPopup = ref(false)
const successOrderData = ref<any>(null)

// Format delivery info into a single address string for backend
const formatDeliveryAddress = computed(() => {
  if (!isDeliveryInfoValid.value) return null

  const parts = [
    deliveryInfo.value.unit,
    deliveryInfo.value.floor,
    deliveryInfo.value.building,
    deliveryInfo.value.street,
    deliveryInfo.value.barangay,
    deliveryInfo.value.city,
    deliveryInfo.value.province,
  ].filter(Boolean)

  let address = parts.join(', ')

  if (deliveryInfo.value.landmark) {
    address += ` (Near ${deliveryInfo.value.landmark})`
  }

  if (deliveryInfo.value.remarks) {
    address += ` - ${deliveryInfo.value.remarks}`
  }

  return address
})

// Complete order validation - removed unused canCreateOrder computed property

// === ORDER MANAGEMENT STATE ===
const selectedOrder = ref<Order | null>(null)

// Filters
const statusFilter = ref('')
const searchQuery = ref('')
const sortBy = ref('createdAt')
const sortOrder = ref('desc')

// === COMPUTED PROPERTIES ===
const filteredProducts = computed(() => {
  let filtered = products.value

  if (productSearch.value) {
    const search = productSearch.value.toLowerCase()
    filtered = filtered.filter(
      (p: Product) =>
        p.name.toLowerCase().includes(search) ||
        p.description?.toLowerCase().includes(search)
    )
  }

  if (selectedCategory.value) {
    filtered = filtered.filter(
      (p: Product) => p.category.id === selectedCategory.value
    )
  }

  return filtered
})

const subtotal = computed(() => {
  return cartItems.value.reduce(
    (sum, item) => sum + item.product.price * item.quantity,
    0
  )
})

const shippingCost = computed(() => {
  if (orderType.value === 'in-store') return 0

  switch (shippingMethod.value) {
    case 'standard':
      return 250.0 // ₱250
    case 'express':
      return 750.0 // ₱750
    case 'overnight':
      return 1250.0 // ₱1,250
    default:
      return 250.0
  }
})

const total = computed(() => {
  return Math.max(0, subtotal.value + shippingCost.value - discountAmount.value)
})

const filteredOrders = computed(() => {
  let filtered = orders.value

  // Status filter
  if (statusFilter.value) {
    filtered = filtered.filter(
      (order: Order) => order.status === statusFilter.value
    )
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

  // Sort based on selected criteria
  return filtered.sort((a: Order, b: Order) => {
    let aValue: any, bValue: any

    switch (sortBy.value) {
      case 'createdAt':
        aValue = new Date(a.createdAt).getTime()
        bValue = new Date(b.createdAt).getTime()
        break
      case 'referenceNumber':
        aValue = a.referenceNumber.toLowerCase()
        bValue = b.referenceNumber.toLowerCase()
        break
      case 'customerName':
        aValue = `${a.customer.firstName} ${a.customer.lastName}`.toLowerCase()
        bValue = `${b.customer.firstName} ${b.customer.lastName}`.toLowerCase()
        break
      case 'total':
        aValue = a.total
        bValue = b.total
        break
      case 'status':
        aValue = a.status
        bValue = b.status
        break
      default:
        aValue = new Date(a.createdAt).getTime()
        bValue = new Date(b.createdAt).getTime()
    }

    if (sortOrder.value === 'asc') {
      return aValue > bValue ? 1 : aValue < bValue ? -1 : 0
    } else {
      return aValue < bValue ? 1 : aValue > bValue ? -1 : 0
    }
  })
})

// Status counts for tabs
const allOrdersCount = computed(() => orders.value.length)
const pendingOrdersCount = computed(() => orders.value.filter((order: Order) => order.status === 'pending').length)
const confirmedOrdersCount = computed(() => orders.value.filter((order: Order) => order.status === 'confirmed').length)
const completedOrdersCount = computed(() => orders.value.filter((order: Order) => order.status === 'completed').length)
const cancelledOrdersCount = computed(() => orders.value.filter((order: Order) => order.status === 'cancelled').length)

// === CREATE ORDER FUNCTIONS ===
const searchCustomers = async () => {
  if (customerSearch.value.length < 2) {
    customerSearchResults.value = []
    showCustomerDropdown.value = false
    return
  }

  try {
    await loadCustomers(SEARCH_CUSTOMERS, {
      search: customerSearch.value,
    })

    if (customersResult.value?.customers) {
      customerSearchResults.value = customersResult.value.customers
      showCustomerDropdown.value = true
    }
  } catch (err: any) {
    console.error('Error searching customers:', err.message)
  }
}

const selectCustomer = (customer: Customer) => {
  selectedCustomer.value = customer
  customerSearch.value = customer.fullName
  customerSearchResults.value = []
  showCustomerDropdown.value = false
}

const clearCustomer = () => {
  selectedCustomer.value = null
  customerSearch.value = ''
  showCustomerDropdown.value = false
}

const createCustomer = async () => {
  customerError.value = ''

  try {
    const result = await createNewCustomer({
      firstName: newCustomer.value.firstName,
      lastName: newCustomer.value.lastName,
      email: newCustomer.value.email,
      mobile: newCustomer.value.mobile,
    })

    if (result?.data?.createCustomer) {
      // Select the new customer
      selectCustomer(result.data.createCustomer)

      // Reset form
      newCustomer.value = { firstName: '', lastName: '', email: '', mobile: '' }
      customerError.value = ''

      toast.success('Customer created successfully!')
    }
  } catch (err: any) {
    customerError.value = err.message || 'Failed to create customer'
  }
}

// Cart functions
const removeFromCart = (productId: string) => {
  cartItems.value = cartItems.value.filter(
    (item) => item.product.id !== productId
  )
}

const updateQuantity = (productId: string, newQuantity: number) => {
  const item = cartItems.value.find((item) => item.product.id === productId)
  // Find the current product data to get accurate stock quantity
  const currentProduct = products.value.find((p: any) => p.id === productId)

  if (item && currentProduct && newQuantity > 0 && newQuantity <= currentProduct.stockQuantity) {
    item.quantity = newQuantity
  } else if (item && currentProduct && newQuantity > currentProduct.stockQuantity) {
    // Show error message when user tries to exceed current stock
    toast.error(`Cannot add ${newQuantity} ${currentProduct.name}. Only ${currentProduct.stockQuantity} available.`)
  }
}

const clearCart = () => {
  cartItems.value = []
}

// Reset entire order workflow
const resetOrder = () => {
  clearCart()
  clearCustomer()
  removeVoucher()
  // Reset delivery info
  deliveryInfo.value = {
    province: '',
    city: '',
    barangay: '',
    street: '',
    unit: '',
    floor: '',
    building: '',
    landmark: '',
    remarks: '',
  }
  deliveryNotes.value = ''
  deliveryDatePreference.value = ''
  currentStep.value = 'products'
  orderType.value = 'in-store'
  shippingMethod.value = 'standard'
  paymentMethod.value = 'cash'
  newCustomer.value = { firstName: '', lastName: '', email: '', mobile: '' }
  customerError.value = ''
}

// Voucher functions
const applyVoucher = async () => {
  if (!voucherCode.value.trim()) return

  voucherError.value = ''

  try {
    await validateVoucherCode(VALIDATE_VOUCHER, {
      code: voucherCode.value.trim(),
      subtotal: subtotal.value,
    })

    if (voucherResult.value?.validateVoucher) {
      const voucher = voucherResult.value.validateVoucher
      appliedVoucher.value = voucher

      // Calculate discount
      if (voucher.discountType === 'percentage') {
        discountAmount.value =
          Math.round(((subtotal.value * voucher.discountValue) / 100) * 100) /
          100
      } else if (voucher.discountType === 'fixed_amount') {
        discountAmount.value = Math.min(voucher.discountValue, subtotal.value)
      }

      voucherCode.value = '' // Clear input after successful application
    } else {
      voucherError.value = 'Invalid or expired voucher code'
    }
  } catch (err: any) {
    voucherError.value = err.message || 'Failed to validate voucher'
    console.error('Error applying voucher:', err)
  }
}

const removeVoucher = () => {
  appliedVoucher.value = null
  discountAmount.value = 0
  voucherCode.value = ''
  voucherError.value = ''
}

// Order creation
const createOrder = async () => {
  if (cartItems.value.length === 0) return

  // Validate stock availability for all cart items
  const stockValidationErrors = []
  for (const item of cartItems.value) {
    if (item.quantity > item.product.stockQuantity) {
      stockValidationErrors.push(
        `${item.product.name}: Requested ${item.quantity}, but only ${item.product.stockQuantity} available`
      )
    }
  }

  if (stockValidationErrors.length > 0) {
    toast.error(
      `Stock validation failed:\n${stockValidationErrors.join('\n')}`
    )
    return
  }

  // Validate delivery address for online orders
  if (orderType.value === 'online') {
    if (
      !deliveryInfo.value.province.trim() ||
      !deliveryInfo.value.city.trim() ||
      !deliveryInfo.value.barangay.trim() ||
      !deliveryInfo.value.street.trim()
    ) {
      toast.error(
        'Please fill in all required delivery address fields (Province, City, Barangay, Street) for online orders'
      )
      return
    }
  }

  let customerId = selectedCustomer.value?.id

  // Create new customer if not selected and form is filled
  if (!selectedCustomer.value) {
    if (!isCustomerFormValid.value) {
      toast.error('Please fill in all customer information fields')
      return
    }

    try {
      const result = await createNewCustomer({
        firstName: newCustomer.value.firstName,
        lastName: newCustomer.value.lastName,
        email: newCustomer.value.email,
        mobile: newCustomer.value.mobile,
      })

      if (result?.data?.createCustomer) {
        customerId = result.data.createCustomer.id
        selectedCustomer.value = result.data.createCustomer
      } else {
        throw new Error('Failed to create customer')
      }
    } catch (err: any) {
      toast.error(`Error creating customer: ${err.message}`)
      return
    }
  }

  if (!customerId) {
    toast.error('Please select or create a customer')
    return
  }

  try {
    const orderItems = cartItems.value.map((item) => ({
      productId: item.product.id,
      quantity: item.quantity,
      unitPrice: item.product.price,
    }))

    const result = await createNewOrder({
      customerId: customerId,
      items: orderItems,
      orderType: orderType.value,
      shippingMethod:
        orderType.value === 'online' ? shippingMethod.value : null,
      paymentMethod: paymentMethod.value,
      voucherCode: appliedVoucher.value?.code || null,
      deliveryAddress:
        orderType.value === 'online'
          ? formatDeliveryAddress.value || null
          : null,
      deliveryNotes: deliveryNotes.value || null,
      deliveryDatePreference: deliveryDatePreference.value
        ? new Date(deliveryDatePreference.value).toISOString()
        : null,
    })

    if (result?.data?.createOrder) {
      const order = result.data.createOrder
      toast.success('Order created successfully!')

      // Show success popup with order details
      successOrderData.value = order
      showSuccessPopup.value = true

      // Don't reset and switch views immediately - do it when popup closes

      // Refresh orders list and products (to update stock quantities)
      await fetchOrders()
      await fetchProducts()
    }
  } catch (err: any) {
    console.error('Error creating order:', err.message)
    toast.error(`Error: ${err.message}`)
  }
}

// === ORDER MANAGEMENT FUNCTIONS ===
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

const selectOrder = (order: Order) => {
  selectedOrder.value = order
}

const clearSelection = () => {
  selectedOrder.value = null
}

const updateOrderStatus = async (
  newStatus: 'pending' | 'confirmed' | 'completed' | 'cancelled'
) => {
  if (!selectedOrder.value) return

  console.log('Attempting to update order status to:', newStatus)
  console.log('Selected order ID:', selectedOrder.value.id)

  // Show confirmation dialog
  const statusMessages = {
    pending: 'Mark this order as Pending',
    confirmed: 'Confirm this order',
    completed: 'Mark this order as Completed',
    cancelled: 'Cancel this order',
  }

  const confirmMessage = `${statusMessages[newStatus]}?\n\nOrder: ${selectedOrder.value.referenceNumber}\nCustomer: ${selectedOrder.value.customer.fullName || selectedOrder.value.customer.email}`

  if (!confirm(confirmMessage)) {
    return
  }

  try {
    const result = await updateStatus({
      id: selectedOrder.value.id,
      status: newStatus,
    })

    console.log('Update result:', result) // Debug log

    // Check for GraphQL errors
    if (result?.errors && result.errors.length > 0) {
      console.error('GraphQL errors:', result.errors)
      const errorMessage = result.errors.map((e) => e.message).join(', ')
      toast.error(`Failed to update order status: ${errorMessage}`)
      return
    }

    if (result?.data?.updateOrderStatus) {
      toast.success(`Order status updated to ${newStatus}`)

      // Update the selectedOrder directly with the new status first (immediate UI update)
      if (selectedOrder.value) {
        selectedOrder.value = {
          ...selectedOrder.value,
          status: newStatus
        }
      }

      // Refetch orders to get fresh data from server
      await fetchOrders()

      // Update selectedOrder with fresh data from the refetched orders
      if (selectedOrder.value) {
        const freshOrder = orders.value.find(
          (o: Order) => o.id === selectedOrder.value!.id
        )
        if (freshOrder) {
          selectedOrder.value = { ...freshOrder }
        }
      }

      // Optional: Show success message
      // You could replace this with a toast notification
      console.log(
        `✅ Order ${selectedOrder.value?.referenceNumber} status updated to ${newStatus}`
      )
    } else {
      // Handle case where mutation succeeded but response structure is unexpected
      console.warn(
        'Update completed but response structure unexpected:',
        result
      )
      console.warn(
        'Expected updateOrderStatus in result.data, got:',
        result?.data
      )
      // Refetch orders to ensure UI is in sync
      await fetchOrders()
    }
  } catch (err: any) {
    console.error('Error updating order status:', err)
    console.error('Error message:', err.message || err)
    console.error('Error stack:', err.stack)
    console.error('GraphQL errors:', err.graphQLErrors)
    console.error('Network error:', err.networkError)
    console.error('Full error object:', JSON.stringify(err, null, 2))

    let errorMessage = 'Unknown error'
    if (err.graphQLErrors && err.graphQLErrors.length > 0) {
      errorMessage = err.graphQLErrors.map((e: any) => e.message).join(', ')
    } else if (err.networkError) {
      errorMessage = `Network error: ${err.networkError.message}`
    } else if (err.message) {
      errorMessage = err.message
    }

    toast.error(`Failed to update order status. Error: ${errorMessage}`)
  }
}

// === PDF GENERATION ===
const generateOrderPDF = (order: Order) => {
  const doc = new jsPDF()
  
  // Set up document
  doc.setFontSize(20)
  doc.text('Order Receipt', 20, 30)
  
  // Order details
  doc.setFontSize(12)
  doc.text(`Order #: ${order.referenceNumber}`, 20, 50)
  doc.text(`Date: ${formatDate(order.createdAt)}`, 20, 60)
  doc.text(`Status: ${order.status.charAt(0).toUpperCase() + order.status.slice(1)}`, 20, 70)
  
  // Customer information
  doc.setFontSize(14)
  doc.text('Customer Information:', 20, 90)
  doc.setFontSize(12)
  doc.text(`Name: ${order.customer.firstName} ${order.customer.lastName}`, 20, 105)
  doc.text(`Email: ${order.customer.email}`, 20, 115)
  
  let customerYPos = 125
  
  if (order.customer.mobile) {
    doc.text(`Mobile: ${order.customer.mobile}`, 20, customerYPos)
    customerYPos += 10
  }
  
  // Add delivery address to customer information if it exists
  if (order.orderType === 'online' && order.deliveryAddress) {
    doc.text(`Delivery Address: ${order.deliveryAddress}`, 20, customerYPos)
    customerYPos += 10
  }
  
  // Order type and delivery info
  let yPos = customerYPos + 15
  doc.setFontSize(14)
  doc.text('Order Details:', 20, yPos)
  doc.setFontSize(12)
  yPos += 15
  doc.text(`Order Type: ${order.orderType?.charAt(0).toUpperCase() + order.orderType?.slice(1) || 'N/A'}`, 20, yPos)
  yPos += 10
  
  if (order.deliveryNotes) {
    doc.text(`Delivery Notes: ${order.deliveryNotes}`, 20, yPos)
    yPos += 10
  }
  
  // Order items
  yPos += 10
  doc.setFontSize(14)
  doc.text('Order Items:', 20, yPos)
  yPos += 15
  
  // Table headers
  doc.setFontSize(10)
  doc.text('Item', 20, yPos)
  doc.text('Qty', 120, yPos)
  doc.text('Price', 150, yPos)
  doc.text('Total', 180, yPos)
  yPos += 10
  
  // Draw line under headers
  doc.line(20, yPos - 2, 200, yPos - 2)
  
  // Calculate totals if not available
  let calculatedSubtotal = 0
  order.orderItems.forEach((item: any) => {
    const itemTotal = item.quantity * item.product.price
    calculatedSubtotal += itemTotal
    
    doc.text(item.product.name, 20, yPos)
    doc.text(item.quantity.toString(), 120, yPos)
    doc.text(`₱${formatPrice(item.product.price)}`, 150, yPos)
    doc.text(`₱${formatPrice(itemTotal)}`, 180, yPos)
    yPos += 10
  })
  
  // Totals section
  yPos += 10
  doc.line(20, yPos - 2, 200, yPos - 2)
  
  const subtotal = (order as any).subtotal || calculatedSubtotal
  const discountAmount = (order as any).discountAmount || 0
  
  doc.text(`Subtotal: ₱${formatPrice(subtotal)}`, 150, yPos)
  yPos += 10
  
  if (discountAmount > 0) {
    doc.text(`Discount: -₱${formatPrice(discountAmount)}`, 150, yPos)
    yPos += 10
  }
  
  doc.setFontSize(12)
  doc.text(`Total: ₱${formatPrice(order.total)}`, 150, yPos)
  
  // Payment method
  yPos += 20
  doc.text(`Payment Method: ${order.paymentMethod?.charAt(0).toUpperCase() + order.paymentMethod?.slice(1) || 'N/A'}`, 20, yPos)
  
  // Save the PDF
  doc.save(`Order_${order.referenceNumber}.pdf`)
  
  toast.success('PDF receipt downloaded successfully!')
}

// === DATA FETCHING ===
// Apollo Client queries - simplified to original working state
const {
  result: ordersResult,
  loading,
  error: ordersError,
  refetch: refetchOrders,
} = useQuery(GET_ORDERS)
const orders = computed(() => ordersResult.value?.orders || [])
const error = computed(() =>
  ordersError.value ? `GraphQL Error: ${ordersError.value.message}` : ''
)


const { result: productsResult, loading: productsLoading, refetch: refetchProducts } =
  useQuery(GET_PRODUCTS, {}, {
    fetchPolicy: 'cache-first',
    errorPolicy: 'all'
  })
const products = computed(() => productsResult.value?.products || [])

const { result: categoriesResult } = useQuery(GET_CATEGORIES, {}, {
  fetchPolicy: 'cache-first',
  errorPolicy: 'all'
})
const categories = computed(() => categoriesResult.value?.categories || [])

const { mutate: updateStatus, loading: updatingStatus } =
  useMutation(UPDATE_ORDER_STATUS)

const { load: loadCustomers, result: customersResult } =
  useLazyQuery(SEARCH_CUSTOMERS)

const { mutate: createNewCustomer, loading: creatingCustomer } =
  useMutation(CREATE_CUSTOMER)

const {
  load: validateVoucherCode,
  result: voucherResult,
} = useLazyQuery(VALIDATE_VOUCHER)

const { mutate: createNewOrder, loading: creatingOrder } =
  useMutation(CREATE_ORDER)

// === CART STORE ===
const cartStore = useCartStore()

const fetchOrders = async () => {
  await refetchOrders()
  // Also refresh products to get updated stock quantities
  await refetchProducts()
}

const fetchProducts = async () => {
  await refetchProducts()
}

// Categories are automatically fetched via Apollo query

// === NAVIGATION FUNCTIONS ===
const switchToCreateOrder = () => {
  currentView.value = 'create'
  currentStep.value = 'products'
  resetOrder()
}

const switchToManageOrders = () => {
  currentView.value = 'manage'
  clearSelection()
  fetchOrders()
}

const closeSuccessPopup = () => {
  console.log('Closing success popup')
  showSuccessPopup.value = false
  resetOrder()
  currentView.value = 'manage'
}

// === CART FUNCTIONS ===
const addToCart = (product: any) => {
  // Try to add item to cart (cart store will check stock limits)
  const success = cartStore.addItem(
    {
      id: product.id,
      name: product.name,
      price: product.price,
      photoUrl: product.photoUrl,
      stockQuantity: product.stockQuantity,
    },
    1
  )

  if (success) {
    cartStore.openCart()
  } else {
    toast.warning(`Cannot add more items. Only ${product.stockQuantity} in stock.`)
  }
}

const populateOrderFromCart = () => {
  const cartOrderItems = cartStore.getCartItemsForOrder()

  // Update stock quantities with current data before transferring to local cart
  cartItems.value = cartOrderItems.map((item: any) => {
    const currentProduct = products.value.find((p: any) => p.id === item.product.id)
    if (currentProduct) {
      return {
        ...item,
        product: {
          ...item.product,
          stockQuantity: currentProduct.stockQuantity
        }
      }
    }
    return item
  })

  currentView.value = 'create'
  currentStep.value = 'products'
  cartStore.clearCart()
  cartStore.closeCart()
}

// Initialize data on mount
onMounted(async () => {
  console.log('=== UnifiedOrders mounted ===')
  console.log('Initial loading state:', loading.value)
  console.log('Initial orders:', orders.value)
  console.log('Initial error:', ordersError.value)
  console.log('Orders result:', ordersResult.value)

  // Check for create mode query parameter
  console.log('UnifiedOrders: Route query:', route.query)
  if (route.query.mode === 'create') {
    console.log('UnifiedOrders: Switching to Create New Order mode from query parameter')
    currentView.value = 'create'

    // Auto-populate with cart items if cart has items
    if (cartStore.items.length > 0) {
      console.log('UnifiedOrders: Auto-populating order with cart items:', cartStore.items.length, 'items')
      setTimeout(() => {
        populateOrderFromCart()
      }, 100) // Small delay to ensure components are ready
    } else {
      console.log('UnifiedOrders: No cart items to populate')
    }
  } else {
    console.log('UnifiedOrders: No create mode detected, staying in manage mode')
  }

  // Check if auth token exists
  const authToken = localStorage.getItem('auth_token')
  const authUser = localStorage.getItem('auth_user')
  console.log('Auth token exists:', !!authToken)
  console.log('Auth token (first 50 chars):', authToken ? authToken.substring(0, 50) + '...' : 'null')
  console.log('Auth user:', authUser)

  if (!authToken) {
    console.warn('No auth token found in localStorage. Please login first.')
  }

  // Test the GraphQL query directly
  if (authToken) {
    console.log('Testing GraphQL query with current token...')
    try {
      await refetchOrders()
      console.log('Refetch completed')
    } catch (err) {
      console.error('Refetch failed:', err)
    }
  }

  // Make populateOrderFromCart globally accessible
  ;(window as any).populateOrderFromCart = populateOrderFromCart
})

// Watch for loading state changes
watch([loading, ordersError], ([newLoading, newError]) => {
  console.log('Loading state changed:', newLoading)
  console.log('Error state changed:', newError)
  if (newError) {
    console.error('Orders query error details:', newError)
  }
})

// Watch for route query parameter changes
watch(() => route.query.mode, (newMode) => {
  console.log('Route query mode changed:', newMode)
  if (newMode === 'create') {
    console.log('Switching to Create New Order mode from route change')
    currentView.value = 'create'
    currentStep.value = 'products'

    // Auto-populate with cart items if cart has items
    if (cartStore.items.length > 0) {
      console.log('Auto-populating order with cart items:', cartStore.items.length, 'items')
      setTimeout(() => {
        populateOrderFromCart()
      }, 100) // Small delay to ensure components are ready
    }
  } else if (newMode === 'manage' || !newMode) {
    console.log('Switching to Manage Orders mode from route change')
    currentView.value = 'manage'
    clearSelection()
  }
})



// Cart functions already defined above

// Prevent TypeScript warnings
void filteredProducts
void searchCustomers
void createCustomer
void resetOrder
void createOrder
void filteredOrders
void formatDate
void getStatusBadgeClass
void selectOrder
void clearSelection
void updateOrderStatus
void fetchOrders
void switchToCreateOrder
void switchToManageOrders
void closeSuccessPopup
void generateOrderPDF
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Main Navigation Header -->
    <div class="border-b bg-white shadow-sm">
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div class="py-4">
          <div class="flex items-center justify-between">
            <h1 class="text-2xl font-bold text-gray-900">
              Order Management System
            </h1>

            <!-- View Toggle -->
            <div class="flex space-x-2">
              <button
                @click="switchToCreateOrder"
                :class="[
                  'rounded-md px-6 py-2 text-sm font-medium transition-colors',
                  currentView === 'create'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200',
                ]"
              >
                Create New Order
              </button>
              <button
                @click="switchToManageOrders"
                :class="[
                  'rounded-md px-6 py-2 text-sm font-medium transition-colors',
                  currentView === 'manage'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200',
                ]"
              >
                Manage Orders
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- CREATE ORDER VIEW -->
    <div
      v-if="currentView === 'create'"
      class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8"
    >
      <!-- Step Progress Bar -->
      <div class="mb-8">
        <div class="mb-6 flex items-center justify-between">
          <h2 class="text-xl font-semibold text-gray-900">Create New Order</h2>

          <!-- Order Type Toggle -->
          <div class="flex space-x-4">
            <button
              @click="orderType = 'in-store'"
              :class="[
                'rounded-md px-4 py-2 text-sm font-medium transition-colors',
                orderType === 'in-store'
                  ? 'bg-blue-100 text-blue-700'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200',
              ]"
            >
              In-Store
            </button>
            <button
              @click="orderType = 'online'"
              :class="[
                'rounded-md px-4 py-2 text-sm font-medium transition-colors',
                orderType === 'online'
                  ? 'bg-blue-100 text-blue-700'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200',
              ]"
            >
              Online
            </button>
          </div>
        </div>

        <!-- Progress Steps -->
        <nav aria-label="Progress">
          <ol class="flex items-center">
            <li class="relative pr-8 sm:pr-20">
              <div
                class="absolute inset-0 flex items-center"
                aria-hidden="true"
              >
                <div class="h-0.5 w-full bg-gray-200"></div>
              </div>
              <div
                :class="[
                  'relative flex h-8 w-8 items-center justify-center rounded-full transition-colors',
                  currentStep === 'products' || currentStep === 'checkout'
                    ? 'bg-blue-600 hover:bg-blue-900'
                    : 'border-2 border-gray-300 bg-white',
                ]"
              >
                <span
                  :class="[
                    'text-sm font-medium',
                    currentStep === 'products' || currentStep === 'checkout'
                      ? 'text-white'
                      : 'text-gray-500',
                  ]"
                  >1</span
                >
              </div>
              <div
                :class="[
                  'mt-2 text-sm font-medium',
                  currentStep === 'products' || currentStep === 'checkout'
                    ? 'text-gray-900'
                    : 'text-gray-500',
                ]"
              >
                Select Products
              </div>
            </li>

            <li class="relative">
              <div
                :class="[
                  'relative flex h-8 w-8 items-center justify-center rounded-full transition-colors',
                  currentStep === 'checkout'
                    ? 'bg-blue-600 hover:bg-blue-900'
                    : 'border-2 border-gray-300 bg-white',
                ]"
              >
                <span
                  :class="[
                    'text-sm font-medium',
                    currentStep === 'checkout' ? 'text-white' : 'text-gray-500',
                  ]"
                  >2</span
                >
              </div>
              <div
                :class="[
                  'mt-2 text-sm font-medium',
                  currentStep === 'checkout'
                    ? 'text-gray-900'
                    : 'text-gray-500',
                ]"
              >
                Checkout & Customer Info
              </div>
            </li>
          </ol>
        </nav>
      </div>

      <!-- Step 1: Customer Selection -->
      <!-- Step 1: Product Selection (Default step, like Shopee/Lazada) -->
      <div
        v-if="currentStep === 'products'"
        class="grid grid-cols-1 gap-8 lg:grid-cols-3"
      >
        <!-- Left: Product Grid -->
        <div class="lg:col-span-2">
          <div class="rounded-lg border bg-white shadow-sm">
            <!-- Header -->
            <div class="border-b p-6">
              <div class="mb-4 flex items-center justify-between">
                <h3 class="text-xl font-semibold text-gray-900">Products</h3>
              </div>

              <!-- Product Filters -->
              <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                <div>
                  <label class="mb-2 block text-sm font-medium text-gray-700"
                    >Search Products</label
                  >
                  <input
                    v-model="productSearch"
                    type="text"
                    placeholder="Search products..."
                    class="w-full rounded-md border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label class="mb-2 block text-sm font-medium text-gray-700"
                    >Filter by Category</label
                  >
                  <div class="flex flex-wrap gap-2">
                    <button
                      @click="selectedCategory = ''"
                      :class="[
                        'rounded-full px-4 py-2 text-sm font-medium transition-colors',
                        selectedCategory === ''
                          ? 'bg-blue-600 text-white'
                          : 'bg-gray-100 text-gray-700 hover:bg-gray-200',
                      ]"
                    >
                      All
                    </button>
                    <button
                      v-for="category in categories"
                      :key="category.id"
                      @click="selectedCategory = category.id"
                      :class="[
                        'rounded-full px-4 py-2 text-sm font-medium transition-colors',
                        selectedCategory === category.id
                          ? 'bg-blue-600 text-white'
                          : 'bg-gray-100 text-gray-700 hover:bg-gray-200',
                      ]"
                    >
                      {{ category.name }}
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <!-- Products Grid -->
            <div class="max-h-96 overflow-y-auto p-6">
              <div v-if="productsLoading" class="flex justify-center py-8">
                <div class="text-center">
                  <svg
                    class="mx-auto -ml-1 mr-3 h-6 w-6 animate-spin text-blue-600"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                  >
                    <circle
                      class="opacity-25"
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      stroke-width="4"
                    ></circle>
                    <path
                      class="opacity-75"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                    ></path>
                  </svg>
                  <div class="mt-2 text-gray-500">Loading products...</div>
                </div>
              </div>

              <div
                v-else-if="filteredProducts.length === 0"
                class="py-8 text-center"
              >
                <div class="text-gray-500">No products found</div>
              </div>

              <div
                v-else
                class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3"
              >
                <div
                  v-for="product in filteredProducts"
                  :key="product.id"
                  class="overflow-hidden rounded-lg border border-gray-200 transition-shadow hover:shadow-md"
                >
                  <div
                    v-if="product.photoUrl"
                    class="h-32 bg-gray-200 bg-cover bg-center"
                    :style="{ backgroundImage: `url(${product.photoUrl})` }"
                  ></div>
                  <div
                    v-else
                    class="flex h-32 items-center justify-center bg-gray-200"
                  >
                    <span class="text-gray-400">No Image</span>
                  </div>

                  <div class="p-3">
                    <h4 class="mb-1 text-sm font-medium text-gray-900">
                      {{ product.name }}
                    </h4>
                    <p class="mb-2 line-clamp-2 text-xs text-gray-600">
                      {{ product.description }}
                    </p>
                    <div class="mb-2 flex items-center justify-between">
                      <span class="text-sm font-semibold text-gray-900"
                        >₱{{ formatPrice(product.price) }}</span
                      >
                      <span class="text-xs text-gray-500"
                        >Stock:
                        {{
                          formatNumberWithCommas(
                            product.stockQuantity.toString()
                          )
                        }}</span
                      >
                    </div>
                    <button
                      @click="addToCart(product)"
                      :disabled="product.stockQuantity === 0"
                      :class="[
                        'w-full rounded-md px-3 py-2 text-xs font-medium transition-colors',
                        product.stockQuantity === 0
                          ? 'cursor-not-allowed bg-gray-100 text-gray-400'
                          : 'bg-blue-600 text-white hover:bg-blue-700',
                      ]"
                    >
                      <span v-if="product.stockQuantity === 0"
                        >Out of Stock</span
                      >
                      <span v-else>Add to Cart</span>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Right: Cart Summary -->
        <div class="lg:col-span-1">
          <div class="rounded-lg border bg-white shadow-sm">
            <!-- Cart Header -->
            <div class="border-b p-6">
              <h3 class="text-xl font-semibold text-gray-900">Order Summary</h3>
              <div class="mt-2 text-sm text-gray-600">
                {{ cartItems.length }} item{{
                  cartItems.length !== 1 ? 's' : ''
                }}
              </div>
            </div>

            <!-- Cart Items -->
            <div class="max-h-64 overflow-y-auto p-6">
              <div v-if="cartItems.length === 0" class="py-8 text-center">
                <div class="text-gray-500">Cart is empty</div>
                <div class="mt-2 text-sm text-gray-400">
                  Add products to continue
                </div>
              </div>

              <div v-else class="space-y-4">
                <div
                  v-for="item in cartItems"
                  :key="item.product.id"
                  class="flex items-center space-x-3 border-b border-gray-100 py-3"
                >
                  <div
                    class="h-10 w-10 flex-shrink-0 rounded bg-gray-200 bg-cover bg-center"
                    :style="
                      item.product.photoUrl
                        ? { backgroundImage: `url(${item.product.photoUrl})` }
                        : {}
                    "
                  >
                    <div
                      v-if="!item.product.photoUrl"
                      class="flex h-full w-full items-center justify-center text-xs text-gray-400"
                    >
                      IMG
                    </div>
                  </div>

                  <div class="min-w-0 flex-1">
                    <h4 class="truncate text-sm font-medium text-gray-900">
                      {{ item.product.name }}
                    </h4>
                    <p class="text-sm text-gray-600">
                      ₱{{ formatPrice(item.product.price) }}
                    </p>
                  </div>

                  <div class="flex items-center space-x-2">
                    <button
                      @click="
                        updateQuantity(item.product.id, item.quantity - 1)
                      "
                      :disabled="item.quantity <= 1"
                      class="flex h-6 w-6 items-center justify-center rounded-full border border-gray-300 text-sm disabled:opacity-50"
                    >
                      -
                    </button>
                    <span class="w-6 text-center text-sm font-medium">{{
                      item.quantity
                    }}</span>
                    <button
                      @click="
                        updateQuantity(item.product.id, item.quantity + 1)
                      "
                      :disabled="item.quantity >= item.product.stockQuantity"
                      class="flex h-6 w-6 items-center justify-center rounded-full border border-gray-300 text-sm disabled:opacity-50"
                    >
                      +
                    </button>
                  </div>

                  <button
                    @click="removeFromCart(item.product.id)"
                    class="ml-2 text-red-600 hover:text-red-800"
                  >
                    ✕
                  </button>
                </div>
              </div>
            </div>

            <!-- Total and Actions -->
            <div class="space-y-4 border-t p-6">
              <div class="flex justify-between text-lg font-semibold">
                <span>Subtotal:</span>
                <span>₱{{ formatPrice(subtotal) }}</span>
              </div>

              <div class="space-y-2">
                <button
                  @click="currentStep = 'checkout'"
                  :disabled="cartItems.length === 0"
                  :class="[
                    'w-full rounded-md px-4 py-3 font-medium transition-colors',
                    cartItems.length === 0
                      ? 'cursor-not-allowed bg-gray-100 text-gray-400'
                      : 'bg-green-600 text-white hover:bg-green-700',
                  ]"
                >
                  Continue to Checkout
                </button>

                <button
                  @click="clearCart"
                  :disabled="cartItems.length === 0"
                  class="w-full rounded-md bg-gray-100 px-4 py-2 text-gray-700 hover:bg-gray-200 disabled:opacity-50"
                >
                  Clear Cart
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Step 3: Checkout -->
      <div v-if="currentStep === 'checkout'" class="mx-auto max-w-4xl">
        <div class="grid grid-cols-1 gap-8 lg:grid-cols-2">
          <!-- Left: Order Details -->
          <div class="rounded-lg border bg-white p-6 shadow-sm">
            <div class="mb-6 flex items-center justify-between">
              <h3 class="text-xl font-semibold text-gray-900">Order Details</h3>
              <button
                @click="currentStep = 'products'"
                class="rounded-md border border-gray-300 px-4 py-2 text-sm text-gray-600 hover:bg-gray-50 hover:text-gray-800"
              >
                ← Back to Products
              </button>
            </div>

            <!-- Customer Information Form -->
            <div class="mb-6 rounded-md border border-gray-200 bg-gray-50 p-4">
              <h4 class="mb-4 text-sm font-medium text-gray-900">
                Customer Information
              </h4>

              <!-- Search existing customer or create new -->
              <div class="space-y-4">
                <div>
                  <label class="mb-2 block text-sm font-medium text-gray-700">
                    Search Existing Customer (Optional)
                  </label>
                  <div class="relative">
                    <input
                      v-model="customerSearch"
                      @input="searchCustomers"
                      @focus="customerSearch && searchCustomers()"
                      type="text"
                      placeholder="Search by name, email, or mobile..."
                      class="w-full rounded-md border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                    />

                    <!-- Customer search dropdown -->
                    <div
                      v-if="
                        showCustomerDropdown && customerSearchResults.length > 0
                      "
                      class="absolute z-10 mt-1 max-h-32 w-full overflow-y-auto rounded-md border border-gray-300 bg-white shadow-lg"
                    >
                      <div
                        v-for="customer in customerSearchResults"
                        :key="customer.id"
                        @click="selectCustomer(customer)"
                        class="cursor-pointer px-3 py-2 hover:bg-gray-50"
                      >
                        <div class="text-sm font-medium">
                          {{ customer.fullName }}
                        </div>
                        <div class="text-xs text-gray-600">
                          {{ customer.email }} • {{ customer.mobile }}
          </div>
        </div>

        <!-- Sorting Controls -->
        <div class="mb-4 rounded-lg border bg-white p-4 shadow-sm">
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-4">
              <div>
                <label class="block text-sm font-medium text-gray-700">Sort by:</label>
                <select
                  v-model="sortBy"
                  class="mt-1 rounded-md border border-gray-300 px-3 py-1 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                >
                  <option value="createdAt">Date Created</option>
                  <option value="referenceNumber">Order Number</option>
                  <option value="customerName">Customer Name</option>
                  <option value="total">Total Amount</option>
                  <option value="status">Status</option>
                </select>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700">Order:</label>
                <button
                  @click="sortOrder = sortOrder === 'desc' ? 'asc' : 'desc'"
                  class="mt-1 flex items-center space-x-1 rounded-md border border-gray-300 px-3 py-1 text-sm hover:bg-gray-50 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                >
                  <span>{{ sortOrder === 'desc' ? 'Descending' : 'Ascending' }}</span>
                  <svg
                    :class="[
                      'h-4 w-4 transition-transform',
                      sortOrder === 'desc' ? 'rotate-180' : ''
                    ]"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7" />
                  </svg>
                </button>
              </div>
            </div>
          </div>
        </div>
                    </div>
                  </div>

                  <div
                    v-if="selectedCustomer"
                    class="mt-2 rounded-md border border-blue-200 bg-blue-50 p-3"
                  >
                    <div class="text-sm text-blue-800">
                      <div>
                        <strong>Name:</strong> {{ selectedCustomer.fullName }}
                      </div>
                      <div>
                        <strong>Email:</strong> {{ selectedCustomer.email }}
                      </div>
                      <div>
                        <strong>Mobile:</strong> {{ selectedCustomer.mobile }}
                      </div>
                    </div>
                    <button
                      @click="clearCustomer"
                      class="mt-2 text-xs text-red-600 hover:text-red-800"
                    >
                      Use different customer
                    </button>
                  </div>
                </div>

                <!-- Create new customer form (if no customer selected) -->
                <div
                  v-if="!selectedCustomer"
                  class="space-y-3 border-t border-gray-200 pt-3"
                >
                  <h5 class="text-sm font-medium text-gray-700">
                    Or Enter New Customer Details
                  </h5>

                  <div class="grid grid-cols-1 gap-3 md:grid-cols-2">
                    <div>
                      <label
                        class="mb-1 block text-sm font-medium text-gray-700"
                      >
                        First Name <span class="text-red-500">*</span>
                      </label>
                      <input
                        v-model="newCustomer.firstName"
                        type="text"
                        required
                        class="w-full rounded-md border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                      />
                    </div>
                    <div>
                      <label
                        class="mb-1 block text-sm font-medium text-gray-700"
                      >
                        Last Name <span class="text-red-500">*</span>
                      </label>
                      <input
                        v-model="newCustomer.lastName"
                        type="text"
                        required
                        class="w-full rounded-md border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                      />
                    </div>
                  </div>

                  <div>
                    <label class="mb-1 block text-sm font-medium text-gray-700">
                      Email <span class="text-red-500">*</span>
                    </label>
                    <input
                      v-model="newCustomer.email"
                      type="email"
                      required
                      class="w-full rounded-md border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                    />
                  </div>

                  <div>
                    <label class="mb-1 block text-sm font-medium text-gray-700">
                      Mobile Number <span class="text-red-500">*</span>
                    </label>
                    <input
                      v-model="newCustomer.mobile"
                      type="tel"
                      required
                      class="w-full rounded-md border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                    />
                  </div>

                  <div v-if="customerError" class="text-sm text-red-600">
                    {{ customerError }}
                  </div>
                </div>
              </div>
            </div>

            <!-- Order Items -->
            <div class="mb-6">
              <h4 class="mb-3 text-sm font-medium text-gray-900">
                Order Items
              </h4>
              <div class="space-y-3">
                <div
                  v-for="item in cartItems"
                  :key="item.product.id"
                  :class="[
                    'flex items-center justify-between border-b border-gray-100 py-2',
                    item.quantity > item.product.stockQuantity
                      ? 'rounded-md bg-red-50 px-2'
                      : '',
                  ]"
                >
                  <div class="flex items-center space-x-3">
                    <div
                      class="h-10 w-10 flex-shrink-0 rounded bg-gray-200 bg-cover bg-center"
                      :style="
                        item.product.photoUrl
                          ? { backgroundImage: `url(${item.product.photoUrl})` }
                          : {}
                      "
                    >
                      <div
                        v-if="!item.product.photoUrl"
                        class="flex h-full w-full items-center justify-center text-xs text-gray-400"
                      >
                        IMG
                      </div>
                    </div>
                    <div>
                      <div class="text-sm font-medium text-gray-900">
                        {{ item.product.name }}
                        <!-- Stock warning icon -->
                        <span
                          v-if="item.quantity > item.product.stockQuantity"
                          class="ml-1 text-red-500"
                          >⚠️</span
                        >
                      </div>
                      <div class="text-sm text-gray-500">
                        ₱{{ formatPrice(item.product.price) }} ×
                        {{ item.quantity }}
                      </div>
                      <!-- Stock validation message -->
                      <div
                        v-if="item.quantity > item.product.stockQuantity"
                        class="mt-1 text-xs text-red-600"
                      >
                        Only {{ item.product.stockQuantity }} available
                      </div>
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
              <!-- Shipping Method (only for online orders) -->
              <div v-if="orderType === 'online'">
                <label class="mb-2 block text-sm font-medium text-gray-700"
                  >Shipping Method</label
                >
                <select
                  v-model="shippingMethod"
                  class="w-full rounded-md border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                >
                  <option value="standard">Standard Shipping (₱250.00)</option>
                  <option value="express">Express Shipping (₱750.00)</option>
                  <option value="overnight">
                    Overnight Shipping (₱1,250.00)
                  </option>
                </select>
              </div>

              <!-- Delivery Information (only for online orders) -->
              <div
                v-if="orderType === 'online'"
                class="space-y-4 rounded-md bg-gray-50 p-4"
              >
                <h4 class="text-sm font-medium text-gray-900">
                  Delivery Information
                </h4>

                <!-- Delivery Address -->
                <!-- Delivery Address Form -->
                <div class="space-y-4">
                  <h3 class="mb-3 text-sm font-medium text-gray-700">
                    Delivery Address <span class="text-red-500">*</span>
                  </h3>

                  <!-- Required Fields Row 1: Province and City -->
                  <div class="grid grid-cols-2 gap-4">
                    <div>
                      <label
                        class="mb-1 block text-xs font-medium text-gray-600"
                      >
                        Province <span class="text-red-500">*</span>
                      </label>
                      <input
                        v-model="deliveryInfo.province"
                        type="text"
                        placeholder="e.g., Metro Manila"
                        class="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                        required
                      />
                    </div>
                    <div>
                      <label
                        class="mb-1 block text-xs font-medium text-gray-600"
                      >
                        City <span class="text-red-500">*</span>
                      </label>
                      <input
                        v-model="deliveryInfo.city"
                        type="text"
                        placeholder="e.g., Quezon City"
                        class="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                        required
                      />
                    </div>
                  </div>

                  <!-- Required Fields Row 2: Barangay and Street -->
                  <div class="grid grid-cols-2 gap-4">
                    <div>
                      <label
                        class="mb-1 block text-xs font-medium text-gray-600"
                      >
                        Barangay <span class="text-red-500">*</span>
                      </label>
                      <input
                        v-model="deliveryInfo.barangay"
                        type="text"
                        placeholder="e.g., Barangay Santo Domingo"
                        class="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                        required
                      />
                    </div>
                    <div>
                      <label
                        class="mb-1 block text-xs font-medium text-gray-600"
                      >
                        Street <span class="text-red-500">*</span>
                      </label>
                      <input
                        v-model="deliveryInfo.street"
                        type="text"
                        placeholder="e.g., 123 Main Street"
                        class="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                        required
                      />
                    </div>
                  </div>

                  <!-- Optional Fields Row 1: Unit and Floor -->
                  <div class="grid grid-cols-2 gap-4">
                    <div>
                      <label
                        class="mb-1 block text-xs font-medium text-gray-500"
                      >
                        Unit (Optional)
                      </label>
                      <input
                        v-model="deliveryInfo.unit"
                        type="text"
                        placeholder="e.g., Unit 4B"
                        class="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                      />
                    </div>
                    <div>
                      <label
                        class="mb-1 block text-xs font-medium text-gray-500"
                      >
                        Floor (Optional)
                      </label>
                      <input
                        v-model="deliveryInfo.floor"
                        type="text"
                        placeholder="e.g., 4th Floor"
                        class="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                      />
                    </div>
                  </div>

                  <!-- Optional Fields Row 2: Building and Landmark -->
                  <div class="grid grid-cols-2 gap-4">
                    <div>
                      <label
                        class="mb-1 block text-xs font-medium text-gray-500"
                      >
                        Building (Optional)
                      </label>
                      <input
                        v-model="deliveryInfo.building"
                        type="text"
                        placeholder="e.g., SM Aura Tower"
                        class="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                      />
                    </div>
                    <div>
                      <label
                        class="mb-1 block text-xs font-medium text-gray-500"
                      >
                        Landmark (Optional)
                      </label>
                      <input
                        v-model="deliveryInfo.landmark"
                        type="text"
                        placeholder="e.g., Near McDonald's"
                        class="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                      />
                    </div>
                  </div>

                  <!-- Remarks Field -->
                  <div>
                    <label class="mb-1 block text-xs font-medium text-gray-500">
                      Delivery Remarks (Optional)
                    </label>
                    <textarea
                      v-model="deliveryInfo.remarks"
                      placeholder="Special delivery instructions (e.g., gate code, security, preferred time)"
                      rows="2"
                      class="w-full resize-none rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                    ></textarea>
                  </div>
                </div>

                <!-- Delivery Date Preference -->
                <div>
                  <label class="mb-2 block text-sm font-medium text-gray-700">
                    Preferred Delivery Date (Optional)
                  </label>
                  <input
                    v-model="deliveryDatePreference"
                    type="datetime-local"
                    class="w-full rounded-md border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                    :min="new Date().toISOString().slice(0, 16)"
                  />
                </div>

                <!-- Delivery Notes -->
                <div>
                  <label class="mb-2 block text-sm font-medium text-gray-700">
                    Delivery Notes (Optional)
                  </label>
                  <textarea
                    v-model="deliveryNotes"
                    placeholder="Special instructions for delivery (e.g., gate code, landmark, preferred time)"
                    rows="2"
                    class="w-full resize-none rounded-md border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                  ></textarea>
                </div>
              </div>

              <!-- Payment Method -->
              <div>
                <label class="mb-2 block text-sm font-medium text-gray-700"
                  >Payment Method</label
                >
                <select
                  v-model="paymentMethod"
                  class="w-full rounded-md border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                >
                  <option value="cash">Cash</option>
                  <option value="card">Credit Card</option>
                  <option value="digital">Digital Wallet</option>
                </select>
              </div>
            </div>
          </div>

          <!-- Right: Order Summary & Actions -->
          <div class="rounded-lg border bg-white p-6 shadow-sm">
            <h3 class="mb-6 text-xl font-semibold text-gray-900">
              Order Summary
            </h3>

            <!-- Order Totals -->
            <div class="mb-6 space-y-3">
              <div class="flex justify-between text-sm">
                <span>Subtotal:</span>
                <span>₱{{ formatPrice(subtotal) }}</span>
              </div>
              <div v-if="shippingCost > 0" class="flex justify-between text-sm">
                <span>Shipping:</span>
                <span>₱{{ formatPrice(shippingCost) }}</span>
              </div>

              <!-- Voucher Section -->
              <div v-if="!appliedVoucher" class="border-t pt-3">
                <div class="flex space-x-2">
                  <input
                    v-model="voucherCode"
                    type="text"
                    placeholder="Enter voucher code"
                    class="flex-1 rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
                    @keyup.enter="applyVoucher"
                    :disabled="applyingVoucher"
                  />
                  <button
                    @click="applyVoucher"
                    :disabled="!voucherCode.trim() || applyingVoucher"
                    class="rounded-md bg-blue-600 px-4 py-2 text-sm text-white hover:bg-blue-700 disabled:cursor-not-allowed disabled:bg-gray-300"
                  >
                    {{ applyingVoucher ? 'Checking...' : 'Apply' }}
                  </button>
                </div>
                <div v-if="voucherError" class="mt-1 text-sm text-red-600">
                  {{ voucherError }}
                </div>
              </div>

              <!-- Applied Voucher -->
              <div v-if="appliedVoucher" class="border-t pt-3">
                <div
                  class="mb-2 flex items-center justify-between text-sm text-green-600"
                >
                  <span class="flex items-center">
                    <svg
                      class="mr-1 h-4 w-4"
                      fill="currentColor"
                      viewBox="0 0 20 20"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                        clip-rule="evenodd"
                      />
                    </svg>
                    {{ appliedVoucher.name }}
                  </span>
                  <button
                    @click="removeVoucher"
                    class="ml-2 text-red-600 hover:text-red-800"
                  >
                    Remove
                  </button>
                </div>
                <div class="flex justify-between text-sm text-green-600">
                  <span>Discount:</span>
                  <span>-₱{{ formatPrice(discountAmount) }}</span>
                </div>
              </div>

              <div
                class="flex justify-between border-t pt-3 text-lg font-semibold"
              >
                <span>Total:</span>
                <span>₱{{ formatPrice(total) }}</span>
              </div>
            </div>

            <!-- Action Buttons -->
            <div class="space-y-3">
              <button
                @click="createOrder"
                :disabled="
                  cartItems.length === 0 ||
                  creatingOrder ||
                  hasStockIssues ||
                  (!selectedCustomer && !isCustomerFormValid) ||
                  (orderType === 'online' && !isDeliveryInfoValid)
                "
                :class="[
                  'w-full rounded-md px-6 py-3 font-medium transition-colors',
                  cartItems.length === 0 ||
                  creatingOrder ||
                  hasStockIssues ||
                  (!selectedCustomer && !isCustomerFormValid) ||
                  (orderType === 'online' && !isDeliveryInfoValid)
                    ? 'cursor-not-allowed bg-gray-100 text-gray-400'
                    : 'bg-green-600 text-white hover:bg-green-700',
                ]"
              >
                <span v-if="creatingOrder">Creating Order...</span>
                <span v-else-if="creatingCustomer">Creating Customer...</span>
                <span v-else-if="hasStockIssues"
                  >Stock Issues - Check Items Above</span
                >
                <span v-else>Create Order (₱{{ formatPrice(total) }})</span>
              </button>

              <button
                @click="resetOrder"
                class="w-full rounded-md bg-gray-100 px-4 py-2 text-gray-700 hover:bg-gray-200"
              >
                Start Over
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- MANAGE ORDERS VIEW -->
    <div v-if="currentView === 'manage'" class="flex h-screen overflow-hidden">
      <!-- Left Section: Order List -->
      <div class="mr-4 flex flex-1 flex-col px-4 sm:px-6 lg:px-8">
        <!-- Header Section - Fixed -->
        <div
          class="mb-4 mt-6 flex-shrink-0 rounded-lg border bg-white p-6 shadow-sm"
        >
          <div class="mb-4 flex items-center justify-between">
            <h2 class="text-xl font-semibold text-gray-900">
              Order Management
            </h2>
            <button
              @click="fetchOrders"
              :disabled="loading || productsLoading"
              class="rounded-md bg-blue-600 px-4 py-2 text-white hover:bg-blue-700 disabled:opacity-50"
            >
              <span v-if="loading || productsLoading">Refreshing...</span>
              <span v-else>Refresh</span>
            </button>
          </div>

          <!-- Search -->
          <div class="mb-4">
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
          <div class="mb-4">
            <div class="flex border-b border-gray-200">
              <button
                @click="statusFilter = ''"
                :class="[
                  'px-4 py-2 text-sm font-medium border-b-2 transition-colors duration-200',
                  statusFilter === ''
                    ? 'text-blue-600 border-blue-600'
                    : 'text-gray-500 border-transparent hover:text-gray-700 hover:border-gray-300'
                ]"
              >
                All
                <span
                  class="ml-2 inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-blue-600 bg-blue-100 rounded-full"
                >
                  {{ allOrdersCount }}
                </span>
              </button>
              <button
                @click="statusFilter = 'pending'"
                :class="[
                  'px-4 py-2 text-sm font-medium border-b-2 transition-colors duration-200',
                  statusFilter === 'pending'
                    ? 'text-blue-600 border-blue-600'
                    : 'text-gray-500 border-transparent hover:text-gray-700 hover:border-gray-300'
                ]"
              >
                Pending
                <span
                  class="ml-2 inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-blue-600 bg-blue-100 rounded-full"
                >
                  {{ pendingOrdersCount }}
                </span>
              </button>
              <button
                @click="statusFilter = 'confirmed'"
                :class="[
                  'px-4 py-2 text-sm font-medium border-b-2 transition-colors duration-200',
                  statusFilter === 'confirmed'
                    ? 'text-blue-600 border-blue-600'
                    : 'text-gray-500 border-transparent hover:text-gray-700 hover:border-gray-300'
                ]"
              >
                Confirmed
                <span
                  class="ml-2 inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-blue-600 bg-blue-100 rounded-full"
                >
                  {{ confirmedOrdersCount }}
                </span>
              </button>
              <button
                @click="statusFilter = 'completed'"
                :class="[
                  'px-4 py-2 text-sm font-medium border-b-2 transition-colors duration-200',
                  statusFilter === 'completed'
                    ? 'text-blue-600 border-blue-600'
                    : 'text-gray-500 border-transparent hover:text-gray-700 hover:border-gray-300'
                ]"
              >
                Completed
                <span
                  class="ml-2 inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-blue-600 bg-blue-100 rounded-full"
                >
                  {{ completedOrdersCount }}
                </span>
              </button>
              <button
                @click="statusFilter = 'cancelled'"
                :class="[
                  'px-4 py-2 text-sm font-medium border-b-2 transition-colors duration-200',
                  statusFilter === 'cancelled'
                    ? 'text-blue-600 border-blue-600'
                    : 'text-gray-500 border-transparent hover:text-gray-700 hover:border-gray-300'
                ]"
              >
                Cancelled
                <span
                  class="ml-2 inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-blue-600 bg-blue-100 rounded-full"
                >
                  {{ cancelledOrdersCount }}
                </span>
              </button>
            </div>
          </div>
        </div>

        <!-- Orders List - Scrollable -->
        <div class="min-h-0 flex-1 overflow-y-auto">
          <div class="rounded-lg border bg-white p-6 shadow-sm">
            <div
              v-if="loading && orders.length === 0"
              class="flex justify-center py-8"
            >
              <div class="text-center">
                <svg
                  class="mx-auto -ml-1 mr-3 h-8 w-8 animate-spin text-blue-600"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                >
                  <circle
                    class="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    stroke-width="4"
                  ></circle>
                  <path
                    class="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  ></path>
                </svg>
                <div class="mt-2 text-gray-500">Loading orders...</div>
              </div>
            </div>

            <div v-else-if="error" class="py-8 text-center">
              <div class="space-y-4 text-center">
                <svg
                  class="mx-auto h-12 w-12 text-red-400"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
                <h3 class="text-lg font-medium text-gray-900">
                  Failed to load orders
                </h3>
                <div class="mb-4 text-red-600">{{ error }}</div>

                <!-- Quick auth fix for development -->
                <div class="space-x-2">
                  <button
                    @click="fetchOrders"
                    class="rounded-md bg-red-600 px-4 py-2 text-white hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500"
                  >
                    Try Again
                  </button>
                  <button
                    @click="$router.push('/products')"
                    class="rounded-md bg-gray-600 px-4 py-2 text-white hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-gray-500"
                  >
                    Go to Products
                  </button>
                </div>
              </div>
            </div>

            <div
              v-else-if="filteredOrders.length === 0"
              class="py-8 text-center"
            >
              <div class="text-gray-500">No orders found</div>
            </div>

            <div v-else class="space-y-4">
              <div
                v-for="order in filteredOrders"
                :key="order.id"
                @click="selectOrder(order)"
                :class="[
                  'cursor-pointer rounded-lg border shadow-sm transition-all hover:shadow-md',
                  selectedOrder?.id === order.id
                    ? 'border-blue-500 bg-blue-50'
                    : 'border-gray-200',
                ]"
              >
                <div class="p-6">
                  <div class="mb-4 flex items-center justify-between">
                    <div>
                      <h4 class="text-lg font-semibold text-gray-900">
                        {{ order.referenceNumber }}
                      </h4>
                      <p class="text-sm text-gray-600">
                        {{ order.customer.email }}
                      </p>
                      <p
                        v-if="order.customer.mobile"
                        class="text-sm text-gray-600"
                      >
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
                          order.status.charAt(0).toUpperCase() + order.status.slice(1)
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
      </div>

      <!-- Right Section: Order Details -->
      <div
        class="mb-6 mr-4 mt-6 flex w-96 flex-col rounded-lg border-l bg-white shadow-lg sm:mr-6 lg:mr-8"
      >
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
              <h3 class="text-xl font-semibold text-gray-900">Order Details</h3>
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
                    selectedOrder.status.charAt(0).toUpperCase() + selectedOrder.status.slice(1)
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
            <h4 class="mb-3 text-lg font-medium text-gray-900">
              Customer Information
            </h4>
            <div class="space-y-2">
              <div
                v-if="selectedOrder.customer.fullName"
                class="flex justify-between"
              >
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
              <div
                v-if="selectedOrder.orderType === 'online' && selectedOrder.deliveryAddress"
                class="flex justify-between"
              >
                <span class="text-sm font-medium text-gray-700">Delivery Address:</span>
                <span class="text-sm text-gray-900">{{
                  selectedOrder.deliveryAddress
                }}</span>
              </div>
            </div>
          </div>

          <!-- Order Items - Scrollable -->
          <div class="min-h-0 flex-1 overflow-y-auto px-6 py-4">
            <h4 class="mb-3 text-lg font-medium text-gray-900">Order Items</h4>
            <div class="space-y-3">
              <div
                v-for="(item, index) in selectedOrder.orderItems"
                :key="index"
                class="flex items-center justify-between border-b border-gray-100 py-3"
              >
                <div class="flex flex-1 items-center space-x-3">
                  <!-- Product Image Thumbnail -->
                  <div
                    class="h-12 w-12 flex-shrink-0 overflow-hidden rounded-lg bg-gray-100"
                  >
                    <img
                      v-if="item.product.photoUrl"
                      :src="item.product.photoUrl"
                      :alt="item.product.name"
                      class="h-full w-full object-cover"
                      @error="
                        ($event.target as HTMLImageElement).style.display =
                          'none'
                      "
                    />
                    <div
                      v-else
                      class="flex h-full w-full items-center justify-center text-gray-400"
                    >
                      <svg
                        class="h-6 w-6"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                        ></path>
                      </svg>
                    </div>
                  </div>
                  <!-- Product Info -->
                  <div class="flex-1">
                    <h5 class="text-sm font-medium text-gray-900">
                      {{ item.product.name }}
                    </h5>
                    <p class="text-sm text-gray-600">
                      ₱{{ formatPrice(item.product.price) }} each
                    </p>
                  </div>
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
                <h4 class="mb-2 text-sm font-medium text-gray-700">
                  Order Information
                </h4>
                <div class="space-y-1 text-sm text-gray-600">
                  <div>
                    Type:
                    <span class="capitalize">{{
                      selectedOrder.orderType
                    }}</span>
                  </div>
                  <div v-if="selectedOrder.shippingMethod">
                    Shipping: {{ selectedOrder.shippingMethod }}
                  </div>
                  <div>Payment: {{ selectedOrder.paymentMethod }}</div>
                  <div v-if="selectedOrder.orderType === 'online' && selectedOrder.deliveryAddress">
                    <span class="font-medium">Delivery Address:</span>
                    <div class="mt-1 pl-2 text-xs text-gray-600 whitespace-pre-line">
                      {{ selectedOrder.deliveryAddress }}
                    </div>
                  </div>
                  <div v-if="selectedOrder.deliveryNotes">
                    <span class="font-medium">Delivery Notes:</span>
                    <div class="mt-1 pl-2 text-xs text-gray-600">
                      {{ selectedOrder.deliveryNotes }}
                    </div>
                  </div>
                  <div v-if="selectedOrder.deliveryDatePreference">
                    <span class="font-medium">Preferred Delivery Date:</span>
                    {{ formatDate(selectedOrder.deliveryDatePreference) }}
                  </div>
                  <div>Created: {{ formatDate(selectedOrder.createdAt) }}</div>
                  <div>Updated: {{ formatDate(selectedOrder.updatedAt) }}</div>
                </div>
              </div>

              <div>
                <h4 class="mb-2 text-sm font-medium text-gray-700">
                  Status Actions
                </h4>
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
                
                <!-- PDF Download Button -->
                <div class="mt-4">
                  <button
                    @click="generateOrderPDF(selectedOrder)"
                    class="w-full flex items-center justify-center space-x-2 rounded-md bg-gray-100 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-200 transition-colors"
                  >
                    <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                    </svg>
                    <span>Download PDF Receipt</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Order Success Popup -->
    <div
      v-if="showSuccessPopup"
      @click="closeSuccessPopup"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 p-4"
    >
      <div
        @click.stop
        class="max-h-screen w-full max-w-md overflow-y-auto rounded-lg bg-white shadow-xl"
      >
        <div class="p-6">
          <!-- Success Header -->
          <div class="mb-6 text-center">
            <div
              class="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-green-100"
            >
              <svg
                class="h-6 w-6 text-green-600"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 13l4 4L19 7"
                ></path>
              </svg>
            </div>
            <h3 class="text-lg font-medium text-gray-900">
              Order Placed Successfully
            </h3>
            <p class="text-sm text-gray-500">
              Order #{{ successOrderData?.referenceNumber }}
            </p>
          </div>

          <!-- Customer Information -->
          <div class="mb-4 border-b pb-4">
            <h4 class="mb-2 font-medium text-gray-900">Customer Information</h4>
            <div class="space-y-1 text-sm text-gray-600">
              <div>
                <span class="font-medium">Name:</span>
                {{ successOrderData?.customer?.firstName }}
                {{ successOrderData?.customer?.lastName }}
              </div>
              <div>
                <span class="font-medium">Email:</span>
                {{ successOrderData?.customer?.email }}
              </div>
              <div>
                <span class="font-medium">Mobile:</span>
                {{ successOrderData?.customer?.mobile }}
              </div>
            </div>
          </div>

          <!-- Delivery Information (for online orders) -->
          <div
            v-if="successOrderData?.orderType === 'online'"
            class="mb-4 border-b pb-4"
          >
            <h4 class="mb-2 font-medium text-gray-900">Delivery Information</h4>
            <div class="space-y-1 text-sm text-gray-600">
              <div><span class="font-medium">Address:</span></div>
              <div
                v-if="successOrderData?.deliveryAddress"
                class="whitespace-pre-line pl-4"
              >
                {{ successOrderData.deliveryAddress }}
              </div>
              <div v-if="successOrderData?.deliveryNotes">
                <span class="font-medium">Notes:</span>
                {{ successOrderData.deliveryNotes }}
              </div>
              <div v-if="successOrderData?.shippingMethod">
                <span class="font-medium">Shipping Method:</span>
                {{ successOrderData.shippingMethod }}
              </div>
              <div v-if="successOrderData?.deliveryDatePreference">
                <span class="font-medium">Delivery Date Preference:</span>
                {{ formatDate(successOrderData.deliveryDatePreference) }}
              </div>
            </div>
          </div>

          <!-- Payment & Order Details -->
          <div class="mb-4 border-b pb-4">
            <h4 class="mb-2 font-medium text-gray-900">Order Details</h4>
            <div class="space-y-1 text-sm text-gray-600">
              <div>
                <span class="font-medium">Order Type:</span>
                {{
                  successOrderData?.orderType?.charAt(0).toUpperCase() + successOrderData?.orderType?.slice(1)
                }}
              </div>
              <div>
                <span class="font-medium">Payment Method:</span>
                {{
                  successOrderData?.paymentMethod?.charAt(0).toUpperCase() + successOrderData?.paymentMethod?.slice(1)
                }}
              </div>
            </div>
          </div>

          <!-- Order Summary -->
          <div class="mb-4 border-b pb-4">
            <h4 class="mb-2 font-medium text-gray-900">Order Summary</h4>
            <div class="space-y-2 text-sm">
              <div class="flex justify-between">
                <span>Subtotal:</span>
                <span>₱{{ formatPrice(successOrderData?.subtotal || 0) }}</span>
              </div>
              <div
                v-if="successOrderData?.discountAmount > 0"
                class="flex justify-between text-green-600"
              >
                <span>Discount:</span>
                <span
                  >-₱{{
                    formatPrice(successOrderData?.discountAmount || 0)
                  }}</span
                >
              </div>
              <div
                class="flex justify-between border-t pt-2 text-lg font-medium"
              >
                <span>Total:</span>
                <span>₱{{ formatPrice(successOrderData?.total || 0) }}</span>
              </div>
            </div>
          </div>

          <!-- Order Confirmation Message -->

          <!-- Close Button -->
          <div class="flex justify-end">
            <button
              @click="closeSuccessPopup"
              class="rounded-md bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
