<template>
  <div class="p-6">
    <h1 class="mb-4 text-2xl font-bold">GraphQL Connection Test</h1>

    <div v-if="loading" class="text-blue-600">Loading...</div>

    <div v-else-if="error" class="text-red-600">Error: {{ error }}</div>

    <div v-else-if="result" class="text-green-600">
      ✅ Connected! Response: {{ result }}
    </div>

    <button
      @click="testConnection"
      class="mt-4 rounded bg-blue-500 px-4 py-2 text-white hover:bg-blue-600"
    >
      Test Connection
    </button>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const loading = ref(false)
const error = ref('')
const result = ref('')

const testConnection = async () => {
  loading.value = true
  error.value = ''
  result.value = ''

  try {
    const response = await fetch('http://localhost:3000/graphql', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        query: 'query { testField }',
      }),
    })

    const data = await response.json()

    if (data.errors) {
      error.value = data.errors[0].message
    } else {
      result.value = data.data.testField
    }
  } catch (e) {
    error.value = e instanceof Error ? e.message : 'Unknown error'
  } finally {
    loading.value = false
  }
}
</script>
