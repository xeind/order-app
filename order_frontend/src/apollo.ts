import { ApolloClient, InMemoryCache, createHttpLink, from } from "@apollo/client/core";
import { setContext } from '@apollo/client/link/context';

// Create the HTTP link to your GraphQL endpoint
const httpLink = createHttpLink({
    uri: import.meta.env.VITE_API_URL || "http://localhost:3000/graphql",
});

// Create the authentication link
const authLink = setContext((_, { headers }) => {
    // Get the authentication token from local storage if it exists
    const token = localStorage.getItem('auth_token');
    // Return the headers to the context so httpLink can read them
    return {
        headers: {
            ...headers,
            authorization: token ? `Bearer ${token}` : "",
        }
    }
});

// Create the Apollo Client instance with simple configuration
const apolloClient = new ApolloClient({
    link: from([authLink, httpLink]),
    cache: new InMemoryCache(),
});

export { apolloClient };
export default apolloClient;
