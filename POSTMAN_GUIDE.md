# Order App GraphQL API - Postman Collection

## Quick Start

1. **Import Collection**: Import `postman-collection.json` into Postman
2. **Import Environment**: Import `postman-environment.json` for easy setup  
3. **Set Environment Variables**:
   - `API_URL`: `https://order-backend-w66j.onrender.com`
   - `AUTH_TOKEN`: (Get from Login mutation)

## 📊 Results Compilation

For comprehensive API testing and result compilation, see **[POSTMAN_RESULTS_COMPILATION.md](POSTMAN_RESULTS_COMPILATION.md)** which covers:
- Automated collection running with result aggregation
- Export and analysis of all GraphQL responses  
- Command-line testing with Newman
- Structured result compilation formats

## Authentication

### 1. Login (Required First)
```graphql
mutation Login($email: String!, $password: String!) {
  loginUser(email: $email, password: $password) {
    token
    user {
      id
      email
      role
    }
  }
}
```

**Variables:**
```json
{
  "email": "manager@orderapp.com",
  "password": "password123"
}
```

**Copy the `token` from response and set it as `AUTH_TOKEN` environment variable.**

---

## Product Management

### 2. Get All Products
```graphql
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
```

### 3. Create Product
```graphql
mutation CreateProduct(
  $name: String!
  $description: String
  $price: Float!
  $categoryId: ID!
  $productType: String
  $photoUrl: String
  $stockQuantity: Int!
) {
  createProduct(
    name: $name
    description: $description
    price: $price
    categoryId: $categoryId
    productType: $productType
    photoUrl: $photoUrl
    stockQuantity: $stockQuantity
  ) {
    product {
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
}
```

**Variables:**
```json
{
  "name": "Test Product",
  "description": "A test product description",
  "price": 99.99,
  "categoryId": "1",
  "productType": "physical",
  "photoUrl": "https://example.com/photo.jpg",
  "stockQuantity": 100
}
```

### 4. Update Product
```graphql
mutation UpdateProduct(
  $id: ID!
  $name: String
  $description: String
  $price: Float
  $categoryId: ID
  $productType: String
  $photoUrl: String
  $stockQuantity: Int
) {
  updateProduct(
    id: $id
    name: $name
    description: $description
    price: $price
    categoryId: $categoryId
    productType: $productType
    photoUrl: $photoUrl
    stockQuantity: $stockQuantity
  ) {
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
```

**Variables:**
```json
{
  "id": "1",
  "name": "Updated Product Name",
  "price": 149.99,
  "stockQuantity": 50
}
```

### 5. Delete Product
```graphql
mutation DeleteProduct($id: ID!) {
  deleteProduct(id: $id)
}
```

**Variables:**
```json
{
  "id": "1"
}
```

---

## Category Management

### 6. Get All Categories
```graphql
query GetCategories {
  categories {
    id
    name
    description
  }
}
```

### 7. Create Category
```graphql
mutation CreateCategory($name: String!, $description: String) {
  createCategory(name: $name, description: $description) {
    category {
      id
      name
      description
    }
  }
}
```

**Variables:**
```json
{
  "name": "New Category",
  "description": "Category description"
}
```

### 8. Update Category
```graphql
mutation UpdateCategory($id: ID!, $name: String, $description: String) {
  updateCategory(id: $id, name: $name, description: $description) {
    category {
      id
      name
      description
    }
  }
}
```

**Variables:**
```json
{
  "id": "1",
  "name": "Updated Category",
  "description": "Updated description"
}
```

### 9. Delete Category
```graphql
mutation DeleteCategory($id: ID!) {
  deleteCategory(id: $id) {
    success
  }
}
```

**Variables:**
```json
{
  "id": "1"
}
```

---

## Order Management

### 10. Get All Orders
```graphql
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
    deliveryAddress
    deliveryNotes
    createdAt
    updatedAt
  }
}
```

### 11. Create Order
```graphql
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
```

**Variables:**
```json
{
  "customerId": "1",
  "items": [
    {
      "productId": "1",
      "quantity": 2
    }
  ],
  "orderType": "delivery",
  "shippingMethod": "standard",
  "paymentMethod": "cash_on_delivery",
  "deliveryAddress": "123 Test St, Test City",
  "deliveryNotes": "Please ring doorbell"
}
```

### 12. Update Order Status
```graphql
mutation UpdateOrderStatus($id: ID!, $status: String!) {
  updateOrderStatus(id: $id, status: $status) {
    id
    referenceNumber
    status
    updatedAt
  }
}
```

**Variables:**
```json
{
  "id": "1",
  "status": "confirmed"
}
```

**Valid Status Values:**
- `"pending"`
- `"confirmed"`
- `"completed"`
- `"cancelled"`

---

## Customer Management

### 13. Search Customers
```graphql
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
```

**Variables:**
```json
{
  "search": "john"
}
```

### 14. Create Customer
```graphql
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
```

**Variables:**
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@example.com",
  "mobile": "+1234567890"
}
```

---

## Voucher Management

### 15. Validate Voucher
```graphql
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
```

**Variables:**
```json
{
  "code": "WELCOME10",
  "subtotal": 100.00
}
```

---

## File Upload (REST API)

### 16. Upload Image
**Method:** `POST`  
**URL:** `{{API_URL}}/upload-image`  
**Headers:**
```
Authorization: Bearer {{AUTH_TOKEN}}
Content-Type: multipart/form-data
```

**Body:** Form-data with key `image` containing the image file.

**Response:**
```json
{
  "url": "https://order-backend-w66j.onrender.com/uploads/filename.jpg"
}
```

---

## Common Response Patterns

### Success Response
```json
{
  "data": {
    "products": [...],
    // or specific mutation result
  }
}
```

### Error Response
```json
{
  "errors": [
    {
      "message": "Error description",
      "locations": [...],
      "path": [...]
    }
  ]
}
```

### Authentication Error
```json
{
  "errors": [
    {
      "message": "Authentication required"
    }
  ]
}
```

---

## Testing Workflow

1. **Start with Login** - Get your auth token
2. **Test basic queries** - Categories, Products, Orders
3. **Test mutations** - Create/Update/Delete operations
4. **Test complex operations** - Order creation with items
5. **Test file uploads** - Image upload endpoint
6. **Test error scenarios** - Invalid IDs, missing auth, etc.

## Environment Variables

Set these in Postman:

| Variable | Value |
|----------|--------|
| `API_URL` | `https://order-backend-w66j.onrender.com` |
| `AUTH_TOKEN` | `<token from login response>` |

## Authentication Notes

- All GraphQL endpoints require authentication except public queries
- Use the `Authorization: Bearer <token>` header
- Tokens expire - re-login if you get auth errors
- Manager role required for category/product mutations