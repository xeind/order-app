import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { apolloClient } from '../apollo'
import { gql } from '@apollo/client/core'

export interface User {
  id: string
  username: string
  email: string
  role: 'manager' | 'staff'
}

export interface LoginResponse {
  loginUser: {
    user: User
    token: string
    errors: string[] | null
  }
}

const LOGIN_MUTATION = gql`
  mutation LoginUser($email: String!, $password: String!) {
    loginUser(email: $email, password: $password) {
      user {
        id
        username
        email
        role
      }
      token
      errors
    }
  }
`

export const useAuthStore = defineStore('auth', () => {
  const token = ref<string | null>(localStorage.getItem('auth_token'))
  const user = ref<User | null>(null)

  // Load user from localStorage on init
  const storedUser = localStorage.getItem('auth_user')
  if (storedUser) {
    try {
      user.value = JSON.parse(storedUser)
    } catch (e) {
      localStorage.removeItem('auth_user')
    }
  }

  const isAuthenticated = computed(() => !!token.value && !!user.value)
  const isManager = computed(() => user.value?.role === 'manager')
  const isStaff = computed(() => user.value?.role === 'staff')

  const login = async (email: string, password: string) => {
    try {
      const { data } = await apolloClient.mutate<LoginResponse>({
        mutation: LOGIN_MUTATION,
        variables: { email, password }
      })

      if (data?.loginUser?.errors && data.loginUser.errors.length > 0) {
        throw new Error(data.loginUser.errors[0])
      }

      if (data?.loginUser?.user && data?.loginUser?.token) {
        token.value = data.loginUser.token
        user.value = data.loginUser.user

        // Store in localStorage
        localStorage.setItem('auth_token', data.loginUser.token)
        localStorage.setItem('auth_user', JSON.stringify(data.loginUser.user))

        return data.loginUser
      } else {
        throw new Error('Invalid login response')
      }
    } catch (error: any) {
      console.error('Login error:', error)
      if (error.graphQLErrors?.[0]?.message) {
        throw new Error(error.graphQLErrors[0].message)
      } else if (error.networkError) {
        throw new Error('Network error. Please check your connection.')
      } else {
        throw new Error(error.message || 'Login failed. Please try again.')
      }
    }
  }

  const logout = () => {
    token.value = null
    user.value = null
    localStorage.removeItem('auth_token')
    localStorage.removeItem('auth_user')

    // Clear Apollo client cache
    apolloClient.resetStore()
  }

  return {
    token: computed(() => token.value),
    user: computed(() => user.value),
    isAuthenticated,
    isManager,
    isStaff,
    login,
    logout
  }
})