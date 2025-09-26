<template>
  <div class="flex h-screen overflow-hidden bg-gray-50">
    <!-- Main Content Area (70%) -->
    <div class="flex min-h-0 flex-1 flex-col">
      <!-- Header - Fixed -->
      <div class="flex-shrink-0 border-b border-gray-200 bg-white px-6 py-4">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-semibold text-gray-900">
              Product Manager
            </h1>
            <p class="mt-1 text-sm text-gray-600">
              Manage your products, inventory, and pricing.
            </p>
          </div>
          <div class="flex space-x-3">
            <button
              @click="openCategoryModal"
              class="inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
            >
              <svg
                class="-ml-1 mr-2 h-5 w-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
                />
              </svg>
              Manage Categories
            </button>
            <button
              @click="startAddProduct"
              class="inline-flex items-center rounded-md border border-transparent bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
            >
              <svg
                class="-ml-1 mr-2 h-5 w-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                />
              </svg>
              Add Product
            </button>
          </div>
        </div>
      </div>

      <!-- Content Area - Scrollable only here -->
      <div class="min-h-0 flex-1 overflow-y-auto">
        <!-- Loading State -->
        <div v-if="loading" class="flex h-full items-center justify-center">
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
            <p class="mt-2 text-gray-500">Loading products...</p>
          </div>
        </div>

        <!-- Error State -->
        <div
          v-else-if="error"
          class="flex h-full flex-col items-center justify-center space-y-4"
        >
          <div class="text-center">
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
            <h3 class="mt-2 text-lg font-medium text-gray-900">
              Failed to load products
            </h3>
            <p class="mt-1 text-red-600">{{ error.message || error }}</p>
            <div class="mt-4 space-x-2">
              <button
                @click="refetchProducts"
                class="rounded-md bg-red-600 px-4 py-2 text-white hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500"
              >
                Retry
              </button>
              <button
                @click="$router.push('/orders')"
                class="rounded-md bg-gray-600 px-4 py-2 text-white hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-gray-500"
              >
                Go to Orders
              </button>
            </div>
          </div>
        </div>

        <!-- Products Grid - Only this area scrolls -->
        <div v-else class="p-6">
          <div
            class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4"
          >
            <div
              v-for="product in products"
              :key="product.id"
              @click="selectProduct(product)"
              :class="[
                'cursor-pointer rounded-lg bg-white p-4 shadow-sm ring-1 ring-gray-900/5 transition-all hover:shadow-md',
                selectedProduct?.id === product.id
                  ? 'bg-blue-50 ring-2 ring-blue-500'
                  : '',
              ]"
            >
              <!-- Product Image -->
              <div v-if="product.photoUrl" class="mb-3">
                <img
                  :src="product.photoUrl"
                  :alt="product.name"
                  class="h-32 w-full rounded-md object-cover"
                />
              </div>

              <div class="flex items-start justify-between">
                <div class="min-w-0 flex-1">
                  <h3 class="truncate text-sm font-medium text-gray-900">
                    {{ product.name }}
                  </h3>
                  <p class="mt-1 line-clamp-2 text-sm text-gray-500">
                    {{ product.description }}
                  </p>
                </div>
                <span
                  class="ml-2 inline-flex items-center rounded-full bg-green-100 px-2 py-0.5 text-xs font-medium text-green-800"
                >
                  {{ product.category.name }}
                </span>
              </div>

              <div class="mt-3 flex items-center justify-between">
                <div class="flex flex-col">
                  <span class="text-lg font-semibold text-gray-900"
                    >₱{{
                      formatNumberWithCommas(product.price.toString())
                    }}</span
                  >
                  <span class="text-xs text-gray-500"
                    >Stock:
                    {{
                      formatNumberWithCommas(product.stockQuantity.toString())
                    }}</span
                  >
                </div>
              </div>

              <div v-if="product.productType" class="mt-2">
                <span
                  class="inline-flex items-center rounded-md bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-600"
                >
                  {{ product.productType }}
                </span>
              </div>
            </div>
          </div>

          <!-- Empty State -->
          <div v-if="products.length === 0" class="py-12 text-center">
            <svg
              class="mx-auto h-12 w-12 text-gray-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2M4 13h2m0 0V9a2 2 0 012-2h2m0 0V6a2 2 0 012-2h2"
              />
            </svg>
            <h3 class="mt-2 text-sm font-medium text-gray-900">No products</h3>
            <p class="mt-1 text-sm text-gray-500">
              Get started by creating a new product.
            </p>
            <div class="mt-6">
              <button
                @click="startAddProduct"
                class="inline-flex items-center rounded-md border border-transparent bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
              >
                <svg
                  class="-ml-1 mr-2 h-5 w-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                  />
                </svg>
                Add Product
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Side Panel (30%) - Fixed, no scrolling -->
    <div class="flex w-96 flex-col border-l border-gray-200 bg-white">
      <!-- Panel Header - Fixed -->
      <div class="flex-shrink-0 border-b border-gray-200 px-6 py-4">
        <div class="flex items-center justify-between">
          <h2 class="text-lg font-medium text-gray-900">
            {{
              panelMode === 'add'
                ? 'Add Product'
                : panelMode === 'edit'
                  ? 'Edit Product'
                  : panelMode === 'view'
                    ? 'Product Details'
                    : 'Product Actions'
            }}
          </h2>
          <button
            v-if="panelMode !== 'default'"
            @click="resetPanel"
            class="text-gray-400 hover:text-gray-600"
          >
            <svg
              class="h-6 w-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>
      </div>

      <!-- Panel Content - Scrollable only if content overflows -->
      <div class="min-h-0 flex-1 overflow-y-auto">
        <div class="p-6">
          <!-- Default State -->
          <div v-if="panelMode === 'default'" class="py-12 text-center">
            <h3 class="mt-2 text-sm font-medium text-gray-900">
              Select a product
            </h3>
            <p class="mt-1 text-sm text-gray-500">
              Choose a product from the list to view details or make changes.
            </p>
          </div>

          <!-- View Mode -->
          <div
            v-else-if="panelMode === 'view' && selectedProduct"
            class="space-y-6"
          >
            <!-- Product Image -->
            <div v-if="selectedProduct.photoUrl" class="text-center">
              <img
                :src="selectedProduct.photoUrl"
                :alt="selectedProduct.name"
                class="mx-auto h-48 w-48 rounded-lg border border-gray-300 object-cover"
              />
            </div>

            <div>
              <h3 class="text-lg font-medium text-gray-900">
                {{ selectedProduct.name }}
              </h3>
              <p class="mt-1 text-sm text-gray-600">
                {{ selectedProduct.description }}
              </p>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700"
                  >Price</label
                >
                <p class="mt-1 text-lg font-semibold text-gray-900">
                  ₱{{
                    formatNumberWithCommas(selectedProduct.price.toString())
                  }}
                </p>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700"
                  >Stock</label
                >
                <p class="mt-1 text-lg font-semibold text-gray-900">
                  {{
                    formatNumberWithCommas(
                      selectedProduct.stockQuantity.toString()
                    )
                  }}
                </p>
              </div>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700"
                >Category</label
              >
              <p class="mt-1 text-sm text-gray-900">
                {{ selectedProduct.category.name }}
              </p>
            </div>

            <div v-if="selectedProduct.productType">
              <label class="block text-sm font-medium text-gray-700"
                >Product Type</label
              >
              <p class="mt-1 text-sm text-gray-900">
                {{ selectedProduct.productType }}
              </p>
            </div>

            <div class="flex space-x-3 pt-4">
              <button
                @click="startEditProduct"
                class="flex-1 rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
              >
                Edit
              </button>
              <button
                @click="confirmDeleteProduct"
                class="flex-1 rounded-md bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700"
              >
                Delete
              </button>
            </div>

            <!-- Quick Add to Cart -->
            <div class="space-y-2 border-t pt-3">
              <button
                @click="addToCart(selectedProduct)"
                :disabled="selectedProduct.stockQuantity === 0"
                :class="[
                  'w-full rounded-md px-4 py-2 text-sm font-medium transition-colors',
                  selectedProduct.stockQuantity === 0
                    ? 'cursor-not-allowed bg-gray-100 text-gray-400'
                    : 'bg-green-600 text-white hover:bg-green-700',
                ]"
              >
                <span v-if="selectedProduct.stockQuantity === 0"
                  >Out of Stock</span
                >
                <span v-else>Add to Cart</span>
              </button>

              <!-- Proceed to Checkout -->
              <button
                @click="proceedToCheckout"
                class="w-full rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700"
              >
                Proceed to Checkout
              </button>
            </div>
          </div>

          <!-- Add/Edit Form -->
          <div v-else-if="panelMode === 'add' || panelMode === 'edit'">
            <form
              @submit.prevent="
                panelMode === 'add' ? createProduct() : updateProduct()
              "
              class="space-y-6"
            >
              <div>
                <label
                  for="panel-name"
                  class="block text-sm font-medium text-gray-700"
                  >Product Name</label
                >
                <input
                  type="text"
                  id="panel-name"
                  v-model="formData.name"
                  required
                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
                  placeholder="Enter product name"
                />
              </div>

              <div>
                <label
                  for="panel-price"
                  class="block text-sm font-medium text-gray-700"
                  >Price</label
                >
                <div class="relative mt-1 rounded-md shadow-sm">
                  <div
                    class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3"
                  >
                    <span class="text-gray-500 sm:text-sm">₱</span>
                  </div>
                  <input
                    type="text"
                    id="panel-price"
                    :value="
                      formData.price > 0
                        ? formatNumberWithCommas(formData.price.toString())
                        : ''
                    "
                    @input="handlePriceInput"
                    @blur="handlePriceBlur"
                    required
                    class="block w-full rounded-md border-gray-300 pl-8 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
                    placeholder="0.00"
                  />
                </div>
              </div>

              <div>
                <label
                  for="panel-category"
                  class="block text-sm font-medium text-gray-700"
                  >Category</label
                >
                <select
                  id="panel-category"
                  v-model="formData.categoryId"
                  required
                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
                >
                  <option value="">Select a category</option>
                  <option
                    v-for="category in categories"
                    :key="category.id"
                    :value="category.id"
                  >
                    {{ category.name }}
                  </option>
                </select>
              </div>

              <div>
                <label
                  for="panel-stock"
                  class="block text-sm font-medium text-gray-700"
                  >Stock Quantity</label
                >
                <input
                  type="text"
                  id="panel-stock"
                  :value="
                    formData.stockQuantity > 0
                      ? formatNumberWithCommas(
                          formData.stockQuantity.toString()
                        )
                      : ''
                  "
                  @input="handleStockInput"
                  @blur="handleStockBlur"
                  required
                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
                  placeholder="0"
                />
              </div>

              <div>
                <label
                  for="panel-description"
                  class="block text-sm font-medium text-gray-700"
                  >Description</label
                >
                <textarea
                  id="panel-description"
                  v-model="formData.description"
                  rows="3"
                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
                  placeholder="Enter product description"
                ></textarea>
              </div>

              <div>
                <label
                  for="panel-type"
                  class="block text-sm font-medium text-gray-700"
                  >Product Type</label
                >
                <select
                  id="panel-type"
                  v-model="formData.productType"
                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
                >
                  <option value="">Select type</option>
                  <option value="physical">Physical</option>
                  <option value="digital">Digital</option>
                </select>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700"
                  >Product Photo</label
                >

                <!-- Current Photo Preview -->
                <div
                  v-if="formData.photoUrl || selectedImagePreview"
                  class="mt-2"
                >
                  <div class="relative inline-block">
                    <img
                      :src="selectedImagePreview || formData.photoUrl"
                      alt="Product preview"
                      class="h-32 w-32 rounded-lg border border-gray-300 object-cover"
                    />
                    <button
                      type="button"
                      @click="removeImage"
                      class="absolute -right-2 -top-2 rounded-full bg-red-500 p-1 text-white hover:bg-red-600"
                    >
                      <svg
                        class="h-4 w-4"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M6 18L18 6M6 6l12 12"
                        />
                      </svg>
                    </button>
                  </div>
                </div>

                <!-- Upload Options -->
                <div class="mt-2 space-y-3">
                  <!-- File Upload -->
                  <div>
                    <label class="block">
                      <input
                        type="file"
                        ref="fileInput"
                        @change="handleFileSelect"
                        accept="image/*"
                        class="sr-only"
                      />
                      <div
                        class="cursor-pointer rounded-md border-2 border-dashed border-gray-300 p-6 text-center transition-colors hover:border-gray-400"
                      >
                        <svg
                          class="mx-auto h-8 w-8 text-gray-400"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"
                          />
                        </svg>
                        <p class="mt-2 text-sm text-gray-600">
                          <span
                            class="font-medium text-blue-600 hover:text-blue-500"
                            >Click to upload</span
                          >
                          or drag and drop
                        </p>
                        <p class="text-xs text-gray-500">
                          PNG, JPG, GIF up to 10MB
                        </p>
                      </div>
                    </label>
                  </div>

                  <!-- URL Input -->
                  <div class="text-center text-sm text-gray-500">or</div>
                  <div>
                    <input
                      type="url"
                      v-model="photoUrlInput"
                      @blur="handleUrlInput"
                      class="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
                      placeholder="Enter image URL (https://example.com/image.jpg)"
                    />
                  </div>
                </div>
              </div>

              <div class="flex space-x-3 pt-4">
                <button
                  type="button"
                  @click="resetPanel"
                  class="flex-1 rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  :disabled="creating || updating"
                  class="flex-1 rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
                >
                  {{
                    panelMode === 'add'
                      ? creating
                        ? 'Creating...'
                        : 'Create Product'
                      : updating
                        ? 'Updating...'
                        : 'Update Product'
                  }}
                </button>
              </div>
            </form>

            <div
              v-if="createError || updateError"
              class="mt-4 rounded-md bg-red-50 p-4"
            >
              <div class="text-sm text-red-700">
                {{ createError || updateError }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Category Management Modal -->
    <div
      v-if="showCategoryModal"
      class="fixed inset-0 z-50 flex items-center justify-center bg-gray-500 bg-opacity-75"
    >
      <div class="mx-4 w-full max-w-2xl rounded-lg bg-white">
        <!-- Modal Header -->
        <div
          class="flex items-center justify-between border-b border-gray-200 px-6 py-4"
        >
          <h3 class="text-lg font-medium text-gray-900">Manage Categories</h3>
          <button
            @click="closeCategoryModal"
            class="text-gray-400 hover:text-gray-600"
          >
            <svg
              class="h-6 w-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>

        <!-- Modal Content -->
        <div class="max-h-96 overflow-y-auto px-6 py-4">
          <!-- Add New Category Form -->
          <div class="mb-6 rounded-lg bg-gray-50 p-4">
            <h4 class="mb-3 text-sm font-medium text-gray-900">
              Add New Category
            </h4>
            <form @submit.prevent="createCategory" class="space-y-3">
              <div class="grid grid-cols-2 gap-3">
                <div>
                  <input
                    v-model="newCategory.name"
                    type="text"
                    placeholder="Category name"
                    required
                    class="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
                  />
                </div>
                <div>
                  <input
                    v-model="newCategory.description"
                    type="text"
                    placeholder="Description (optional)"
                    class="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
                  />
                </div>
              </div>
              <div class="flex justify-end">
                <button
                  type="submit"
                  :disabled="creatingCategory || !newCategory.name.trim()"
                  class="inline-flex items-center rounded-md border border-transparent bg-blue-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50"
                >
                  {{ creatingCategory ? 'Adding...' : 'Add Category' }}
                </button>
              </div>
            </form>
          </div>

          <!-- Categories List -->
          <div class="space-y-2">
            <h4 class="mb-3 text-sm font-medium text-gray-900">
              Existing Categories
            </h4>
            <div
              v-if="categories.length === 0"
              class="py-6 text-center text-gray-500"
            >
              No categories found. Add one above to get started.
            </div>
            <div v-else class="space-y-2">
              <div
                v-for="category in categories"
                :key="category.id"
                class="flex items-center justify-between rounded-lg border border-gray-200 bg-white p-3"
              >
                <!-- View Mode -->
                <div v-if="editingCategory !== category.id" class="flex-1">
                  <div class="flex items-start justify-between">
                    <div class="flex-1">
                      <h5 class="font-medium text-gray-900">
                        {{ category.name }}
                      </h5>
                      <p
                        v-if="category.description"
                        class="text-sm text-gray-500"
                      >
                        {{ category.description }}
                      </p>
                    </div>
                    <div class="ml-4 flex space-x-2">
                      <button
                        @click="startEditCategory(category)"
                        class="text-sm font-medium text-blue-600 hover:text-blue-800"
                      >
                        Edit
                      </button>
                      <button
                        @click="confirmDeleteCategory(category)"
                        class="text-sm font-medium text-red-600 hover:text-red-800"
                      >
                        Delete
                      </button>
                    </div>
                  </div>
                </div>

                <!-- Edit Mode -->
                <div v-else class="flex-1">
                  <form
                    @submit.prevent="updateCategory(category.id)"
                    class="space-y-3"
                  >
                    <div class="grid grid-cols-2 gap-3">
                      <input
                        v-model="editCategoryData.name"
                        type="text"
                        required
                        class="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
                      />
                      <input
                        v-model="editCategoryData.description"
                        type="text"
                        class="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
                      />
                    </div>
                    <div class="flex justify-end space-x-2">
                      <button
                        type="button"
                        @click="cancelEditCategory"
                        class="rounded-md border border-gray-300 bg-white px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-50"
                      >
                        Cancel
                      </button>
                      <button
                        type="submit"
                        :disabled="updatingCategory"
                        class="rounded-md border border-transparent bg-blue-600 px-3 py-1.5 text-sm text-white hover:bg-blue-700 disabled:opacity-50"
                      >
                        {{ updatingCategory ? 'Saving...' : 'Save' }}
                      </button>
                    </div>
                  </form>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Modal Footer -->
        <div class="border-t border-gray-200 bg-gray-50 px-6 py-4">
          <div class="flex justify-end">
            <button
              @click="closeCategoryModal"
              class="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
            >
              Done
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Delete Category Confirmation Modal -->
    <div
      v-if="showDeleteCategoryModal"
      class="z-60 fixed inset-0 flex items-center justify-center bg-gray-500 bg-opacity-75"
    >
      <div class="mx-4 w-full max-w-sm rounded-lg bg-white p-6">
        <div class="flex items-center">
          <div
            class="mx-auto flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full bg-red-100"
          >
            <svg
              class="h-6 w-6 text-red-600"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.996-.833-2.768 0L3.046 16.5c-.77.833.192 2.5 1.732 2.5z"
              />
            </svg>
          </div>
        </div>
        <div class="mt-3 text-center">
          <h3 class="text-lg font-medium leading-6 text-gray-900">
            Delete Category
          </h3>
          <div class="mt-2">
            <p class="text-sm text-gray-500">
              Are you sure you want to delete "{{ categoryToDelete?.name }}"?
              This action cannot be undone.
            </p>
          </div>
        </div>
        <div class="mt-5 flex space-x-3 sm:mt-6">
          <button
            @click="
              ((showDeleteCategoryModal = false), (categoryToDelete = null))
            "
            class="inline-flex w-full justify-center rounded-md border border-gray-300 bg-white px-4 py-2 text-base font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 sm:text-sm"
          >
            Cancel
          </button>
          <button
            @click="deleteCategory"
            :disabled="deletingCategory"
            class="inline-flex w-full justify-center rounded-md border border-transparent bg-red-600 px-4 py-2 text-base font-medium text-white shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 disabled:opacity-50 sm:text-sm"
          >
            {{ deletingCategory ? 'Deleting...' : 'Delete' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Delete Product Confirmation Modal -->
    <div
      v-if="showDeleteModal"
      class="fixed inset-0 z-50 flex items-center justify-center bg-gray-500 bg-opacity-75"
    >
      <div class="mx-4 w-full max-w-sm rounded-lg bg-white p-6">
        <div class="flex items-center">
          <div
            class="mx-auto flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full bg-red-100"
          >
            <svg
              class="h-6 w-6 text-red-600"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.996-.833-2.768 0L3.046 16.5c-.77.833.192 2.5 1.732 2.5z"
              />
            </svg>
          </div>
        </div>
        <div class="mt-3 text-center">
          <h3 class="text-lg font-medium leading-6 text-gray-900">
            Delete Product
          </h3>
          <div class="mt-2">
            <p class="text-sm text-gray-500">
              Are you sure you want to delete "{{ selectedProduct?.name }}"?
              This action cannot be undone.
            </p>
          </div>
        </div>
        <div class="mt-5 flex space-x-3 sm:mt-6">
          <button
            @click="showDeleteModal = false"
            class="inline-flex w-full justify-center rounded-md border border-gray-300 bg-white px-4 py-2 text-base font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 sm:text-sm"
          >
            Cancel
          </button>
          <button
            @click="deleteProduct"
            :disabled="deleting"
            class="inline-flex w-full justify-center rounded-md border border-transparent bg-red-600 px-4 py-2 text-base font-medium text-white shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 disabled:opacity-50 sm:text-sm"
          >
            {{ deleting ? 'Deleting...' : 'Delete' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useQuery, useMutation } from '@vue/apollo-composable'
import { gql } from '@apollo/client/core'
import { useCartStore } from '@/stores/cart'
import { useRouter } from 'vue-router'

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

interface NewProduct {
  name: string
  description: string
  price: number
  categoryId: string
  productType: string
  photoUrl: string
  stockQuantity: number
}

// GraphQL queries and mutations
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

const CREATE_PRODUCT = gql`
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
`

const UPDATE_PRODUCT = gql`
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
`

const DELETE_PRODUCT = gql`
  mutation DeleteProduct($id: ID!) {
    deleteProduct(id: $id)
  }
`

const CREATE_CATEGORY = gql`
  mutation CreateCategory($name: String!, $description: String) {
    createCategory(name: $name, description: $description) {
      category {
        id
        name
        description
      }
    }
  }
`

const UPDATE_CATEGORY = gql`
  mutation UpdateCategory($id: ID!, $name: String, $description: String) {
    updateCategory(id: $id, name: $name, description: $description) {
      category {
        id
        name
        description
      }
    }
  }
`

const DELETE_CATEGORY = gql`
  mutation DeleteCategory($id: ID!) {
    deleteCategory(id: $id) {
      success
    }
  }
`

// Panel states
const panelMode = ref<'default' | 'view' | 'add' | 'edit'>('default')
const selectedProduct = ref<Product | null>(null)

// Cart store
const cartStore = useCartStore()

// Router
const router = useRouter()

// Apollo queries with forceFetch to prevent caching issues
const {
  result: productsResult,
  loading,
  error,
  refetch: refetchProducts,
} = useQuery(
  GET_PRODUCTS,
  {},
  {
    fetchPolicy: 'cache-first',
    errorPolicy: 'all',
    notifyOnNetworkStatusChange: true,
  }
)
const { result: categoriesResult, refetch: refetchCategories } = useQuery(
  GET_CATEGORIES,
  {},
  {
    fetchPolicy: 'cache-first',
    errorPolicy: 'all',
  }
)

// Computed properties from Apollo results
const products = computed(() => productsResult.value?.products || [])
const categories = computed(() => categoriesResult.value?.categories || [])

// Apollo mutations
const { mutate: createProductMutation, loading: creating } =
  useMutation(CREATE_PRODUCT)
const { mutate: updateProductMutation, loading: updating } =
  useMutation(UPDATE_PRODUCT)
const { mutate: deleteProductMutation, loading: deleting } =
  useMutation(DELETE_PRODUCT)
const { mutate: createCategoryMutation, loading: creatingCategory } =
  useMutation(CREATE_CATEGORY)
const { mutate: updateCategoryMutation, loading: updatingCategory } =
  useMutation(UPDATE_CATEGORY)
const { mutate: deleteCategoryMutation, loading: deletingCategory } =
  useMutation(DELETE_CATEGORY)

// Error handling
const createError = ref('')
const updateError = ref('')

// Form data for add/edit
const formData = ref<NewProduct>({
  name: '',
  description: '',
  price: 0,
  categoryId: '',
  productType: '',
  photoUrl: '',
  stockQuantity: 0,
})

// Image upload state
const fileInput = ref<HTMLInputElement>()
const selectedImagePreview = ref<string>('')
const photoUrlInput = ref<string>('')
const selectedFile = ref<File | null>(null)

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

const parseNumberFromCommas = (value: string): number => {
  // Remove commas and convert to number
  return parseFloat(value.replace(/,/g, '')) || 0
}

// Price input handlers
const handlePriceInput = (event: Event) => {
  const target = event.target as HTMLInputElement
  const rawValue = target.value

  // Format the input with commas
  const formattedValue = formatNumberWithCommas(rawValue)
  target.value = formattedValue
}

const handlePriceBlur = (event: Event) => {
  const target = event.target as HTMLInputElement
  const numericValue = parseNumberFromCommas(target.value)
  formData.value.price = numericValue
}

// Stock input handlers
const handleStockInput = (event: Event) => {
  const target = event.target as HTMLInputElement
  const rawValue = target.value

  // Only allow integers for stock (remove decimal points)
  const cleanValue = rawValue.replace(/[^\d]/g, '')
  const formattedValue = formatNumberWithCommas(cleanValue)
  target.value = formattedValue
}

const handleStockBlur = (event: Event) => {
  const target = event.target as HTMLInputElement
  const numericValue = parseNumberFromCommas(target.value)
  formData.value.stockQuantity = Math.floor(numericValue) // Ensure integer
}

// Delete state
const showDeleteModal = ref(false)

// Category management state
const showCategoryModal = ref(false)
const showDeleteCategoryModal = ref(false)
const editingCategory = ref<string | null>(null)
const categoryToDelete = ref<Category | null>(null)
const newCategory = ref({ name: '', description: '' })
const editCategoryData = ref({ name: '', description: '' })

// Panel management functions
const resetPanel = () => {
  panelMode.value = 'default'
  selectedProduct.value = null
  resetForm()
}

const selectProduct = (product: Product) => {
  selectedProduct.value = product
  panelMode.value = 'view'
}

const startAddProduct = () => {
  selectedProduct.value = null
  resetForm()
  panelMode.value = 'add'
}

const startEditProduct = () => {
  if (!selectedProduct.value) return

  formData.value = {
    name: selectedProduct.value.name,
    description: selectedProduct.value.description || '',
    price: selectedProduct.value.price,
    categoryId: selectedProduct.value.category.id,
    productType: selectedProduct.value.productType || '',
    photoUrl: selectedProduct.value.photoUrl || '',
    stockQuantity: selectedProduct.value.stockQuantity,
  }

  // Set up image state for editing
  selectedImagePreview.value = selectedProduct.value.photoUrl || ''
  photoUrlInput.value = selectedProduct.value.photoUrl || ''
  selectedFile.value = null

  panelMode.value = 'edit'
}

const resetForm = () => {
  formData.value = {
    name: '',
    description: '',
    price: 0,
    categoryId: '',
    productType: '',
    photoUrl: '',
    stockQuantity: 0,
  }
  selectedImagePreview.value = ''
  photoUrlInput.value = ''
  selectedFile.value = null
  createError.value = ''
  updateError.value = ''
}

// Image handling functions
const handleFileSelect = (event: Event) => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]

  if (file) {
    // Validate file type
    if (!file.type.startsWith('image/')) {
      alert('Please select an image file')
      return
    }

    // Validate file size (10MB)
    if (file.size > 10 * 1024 * 1024) {
      alert('Image must be smaller than 10MB')
      return
    }

    selectedFile.value = file

    // Create preview
    const reader = new FileReader()
    reader.onload = (e) => {
      selectedImagePreview.value = e.target?.result as string
      formData.value.photoUrl = '' // Clear URL input when file is selected
      photoUrlInput.value = ''
    }
    reader.readAsDataURL(file)
  }
}

const handleUrlInput = () => {
  if (photoUrlInput.value) {
    selectedImagePreview.value = photoUrlInput.value
    formData.value.photoUrl = photoUrlInput.value
    selectedFile.value = null // Clear file when URL is entered
  }
}

const removeImage = () => {
  selectedImagePreview.value = ''
  photoUrlInput.value = ''
  formData.value.photoUrl = ''
  selectedFile.value = null
  if (fileInput.value) {
    fileInput.value.value = ''
  }
}

const uploadImageToServer = async (file: File): Promise<string> => {
  const formData = new FormData()
  formData.append('image', file)

  const token = localStorage.getItem('auth_token')

  try {
    const response = await fetch('http://localhost:3000/upload-image', {
      method: 'POST',
      headers: {
        Authorization: token ? `Bearer ${token}` : '',
      },
      body: formData,
    })

    if (!response.ok) {
      throw new Error('Failed to upload image')
    }

    const data = await response.json()
    return data.url
  } catch (error) {
    console.error('Image upload error:', error)
    throw error
  }
}

const createProduct = async () => {
  createError.value = ''

  try {
    let photoUrl = formData.value.photoUrl

    // Upload image if a file was selected
    if (selectedFile.value) {
      try {
        photoUrl = await uploadImageToServer(selectedFile.value)
      } catch (error) {
        createError.value = 'Failed to upload image. Please try again.'
        return
      }
    }

    const result = await createProductMutation({
      name: formData.value.name,
      description: formData.value.description || null,
      price: formData.value.price,
      categoryId: formData.value.categoryId,
      productType: formData.value.productType || null,
      photoUrl: photoUrl || null,
      stockQuantity: formData.value.stockQuantity,
    })

    if (result?.data?.createProduct?.product) {
      // Select the new product and show it
      selectedProduct.value = result.data.createProduct.product
      panelMode.value = 'view'

      // Refetch to update the products list
      await refetchProducts()

      console.log('Product created successfully!')
    }
  } catch (err: any) {
    createError.value = err.message || 'Failed to create product'
    console.error('Create product error:', err)
  }
}

const updateProduct = async () => {
  if (!selectedProduct.value) return

  updateError.value = ''

  try {
    let photoUrl = formData.value.photoUrl

    // Upload image if a new file was selected
    if (selectedFile.value) {
      try {
        photoUrl = await uploadImageToServer(selectedFile.value)
      } catch (error) {
        updateError.value = 'Failed to upload image. Please try again.'
        return
      }
    }

    const result = await updateProductMutation({
      id: selectedProduct.value.id,
      name: formData.value.name,
      description: formData.value.description || null,
      price: formData.value.price,
      categoryId: formData.value.categoryId,
      productType: formData.value.productType || null,
      photoUrl: photoUrl || null,
      stockQuantity: formData.value.stockQuantity,
    })

    if (result?.data?.updateProduct) {
      // Update selected product and switch to view mode
      selectedProduct.value = result.data.updateProduct
      panelMode.value = 'view'

      // Refetch to update the products list
      await refetchProducts()

      console.log('Product updated successfully!')
    }
  } catch (err: any) {
    updateError.value = err.message || 'Failed to update product'
    console.error('Update product error:', err)
  }
}

const confirmDeleteProduct = () => {
  if (selectedProduct.value) {
    showDeleteModal.value = true
  }
}

const deleteProduct = async () => {
  if (!selectedProduct.value) return

  try {
    const result = await deleteProductMutation({
      id: selectedProduct.value.id,
    })

    if (result?.data?.deleteProduct) {
      // Reset panel
      resetPanel()

      // Refetch to update the products list
      await refetchProducts()

      console.log('Product deleted successfully!')
    } else {
      console.error('Product not found or could not be deleted')
    }
  } catch (err: any) {
    console.error('Delete product error:', err)
  } finally {
    showDeleteModal.value = false
  }
}

// Category management functions
const openCategoryModal = () => {
  showCategoryModal.value = true
  resetCategoryForm()
}

const closeCategoryModal = () => {
  showCategoryModal.value = false
  editingCategory.value = null
  resetCategoryForm()
}

const resetCategoryForm = () => {
  newCategory.value = { name: '', description: '' }
  editCategoryData.value = { name: '', description: '' }
}

const createCategory = async () => {
  if (!newCategory.value.name.trim()) return

  try {
    const result = await createCategoryMutation({
      name: newCategory.value.name,
      description: newCategory.value.description || null,
    })

    if (result?.data?.createCategory?.category) {
      resetCategoryForm()
      await refetchCategories()
      console.log('Category created successfully!')
    }
  } catch (err: any) {
    console.error('Create category error:', err)
  }
}

const startEditCategory = (category: Category) => {
  editingCategory.value = category.id
  editCategoryData.value = {
    name: category.name,
    description: category.description || '',
  }
}

const cancelEditCategory = () => {
  editingCategory.value = null
  resetCategoryForm()
}

const updateCategory = async (categoryId: string) => {
  try {
    const result = await updateCategoryMutation({
      id: categoryId,
      name: editCategoryData.value.name,
      description: editCategoryData.value.description || null,
    })

    if (result?.data?.updateCategory?.category) {
      editingCategory.value = null
      resetCategoryForm()
      await refetchCategories()
      console.log('Category updated successfully!')
    }
  } catch (err: any) {
    console.error('Update category error:', err)
  }
}

const confirmDeleteCategory = (category: Category) => {
  categoryToDelete.value = category
  showDeleteCategoryModal.value = true
}

const deleteCategory = async () => {
  if (!categoryToDelete.value) return

  try {
    const result = await deleteCategoryMutation({
      id: categoryToDelete.value.id,
    })

    if (result?.data?.deleteCategory) {
      await refetchCategories()
      console.log('Category deleted successfully!')
    } else {
      console.error('Category not found or could not be deleted')
    }
  } catch (err: any) {
    console.error('Delete category error:', err)
  } finally {
    showDeleteCategoryModal.value = false
    categoryToDelete.value = null
  }
}

// Add to cart function
const addToCart = (product: Product) => {
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
    console.log(`Added ${product.name} to cart`)
    // You could add a toast notification here
  } else {
    console.warn(`Could not add ${product.name} to cart - stock limit reached`)
    // You could add a toast notification here
  }
}

// Proceed to checkout function
const proceedToCheckout = () => {
  console.log('ProductManager: proceedToCheckout called')
  console.log('ProductManager: Current cart items:', cartStore.items.length)

  // Navigate to orders page and trigger Create New Order workflow
  console.log('ProductManager: Navigating to /orders with mode=create')
  router.push({ path: '/orders', query: { mode: 'create' } })
}

// Component lifecycle - force fresh data on mount
onMounted(async () => {
  console.log('ProductManager mounted - forcing data refresh')
  try {
    await Promise.all([refetchProducts(), refetchCategories()])
    console.log('ProductManager data refreshed successfully')
  } catch (err) {
    console.error('ProductManager mount refresh failed:', err)
  }
})
</script>
