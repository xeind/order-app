<template>
  <div
    class="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8"
  >
    <div class="max-w-md w-full space-y-8">
      <div>
        <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
          Sign in to Order POS
        </h2>
        <p class="mt-2 text-center text-sm text-gray-600">
          Access the point-of-sale system
        </p>
      </div>
      <form class="mt-8 space-y-6" @submit.prevent="handleSubmit">
        <div class="rounded-md shadow-sm -space-y-px">
          <div>
            <label for="email" class="sr-only">Email address</label>
            <input
              id="email"
              v-model="credentials.email"
              name="email"
              type="email"
              autocomplete="email"
              required
              class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
              placeholder="Email address"
            />
          </div>
          <div>
            <label for="password" class="sr-only">Password</label>
            <input
              id="password"
              v-model="credentials.password"
              name="password"
              type="password"
              autocomplete="current-password"
              required
              class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
              placeholder="Password"
            />
          </div>
        </div>

        <div v-if="errorMessage" class="text-red-600 text-sm text-center">
          {{ errorMessage }}
        </div>

        <div>
          <button
            type="submit"
            :disabled="isLoading"
            class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
          >
            <span v-if="isLoading">Signing in...</span>
            <span v-else>Sign in</span>
          </button>
        </div>

        <div class="text-xs text-gray-500 text-center space-y-1">
          <p><strong>Test Accounts:</strong></p>
          <p>Manager: manager@orderapp.com / password123</p>
          <p>Staff: staff@orderapp.com / password123</p>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from "vue";
import { useRouter } from "vue-router";
import { useAuthStore } from "../stores/auth";

const router = useRouter();
const authStore = useAuthStore();

const credentials = reactive({
  email: "",
  password: "",
});

const isLoading = ref(false);
const errorMessage = ref("");

const handleSubmit = async () => {
  if (isLoading.value) return;

  isLoading.value = true;
  errorMessage.value = "";

  try {
    await authStore.login(credentials.email, credentials.password);
    router.push("/");
  } catch (error: any) {
    errorMessage.value =
      error.message || "Login failed. Please check your credentials.";
  } finally {
    isLoading.value = false;
  }
};
</script>
