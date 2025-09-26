# GraphQL Query Results Compilation Guide

## Overview
This guide shows you how to compile all GraphQL query results from the Order App API using Postman's Collection Runner and automated test scripts.

## Method 1: Automated Collection Runner (Recommended)

### Step 1: Set Up Environment
1. Open Postman and import `postman-collection.json`
2. Set environment variables:
   - `API_URL`: `https://order-backend-w66j.onrender.com`
   - `AUTH_TOKEN`: (will be auto-populated after login)

### Step 2: Run Complete Collection
1. Click on the collection "Order App GraphQL API"
2. Click "Run" button (or use Runner tab)
3. Select all requests or choose specific ones:
   - ✅ Authentication → Login
   - ✅ Products → Get All Products  
   - ✅ Categories → Get All Categories
   - ✅ Orders → Get All Orders
   - ✅ Customers → Search Customers
   - ✅ Vouchers → Validate Voucher
   - ✅ Result Compilation → Generate Full Report
4. Click "Run Order App GraphQL API"

### Step 3: View Compiled Results
After the run completes:
1. Check the "Console" tab in Postman (View → Show Postman Console)
2. Look for "GRAPHQL API COMPILATION REPORT" - this contains all results
3. Or access individual results from global variables:
   - `COMPILATION_LOGIN`
   - `COMPILATION_PRODUCTS` 
   - `COMPILATION_CATEGORIES`
   - `COMPILATION_ORDERS`
   - `FINAL_COMPILATION` (complete report)

### Step 4: Export Results
1. Go to Environment/Globals tab
2. Copy the `FINAL_COMPILATION` variable value
3. Save to a JSON file for analysis

## Method 2: Manual Result Collection

### Step 1: Execute Queries Individually
Run each GraphQL query and manually save responses:

#### 1. Authentication
```bash
curl -X POST https://order-backend-w66j.onrender.com/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation{loginUser(email:\"manager@orderapp.com\",password:\"password123\"){token user{id email role}}}"}'
```

#### 2. Products
```bash
curl -X POST https://order-backend-w66j.onrender.com/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"query":"query{products{id name description price stockQuantity category{name}}}"}'
```

#### 3. Categories
```bash
curl -X POST https://order-backend-w66j.onrender.com/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"query":"query{categories{id name description}}"}'
```

#### 4. Orders
```bash
curl -X POST https://order-backend-w66j.onrender.com/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"query":"query{orders{id referenceNumber status total orderType customer{fullName}}}"}'
```

### Step 2: Compile Manually
Create a JSON structure combining all results:
```json
{
  "compilation_timestamp": "2025-01-27T...",
  "api_endpoint": "https://order-backend-w66j.onrender.com/graphql",
  "results": {
    "authentication": { ... },
    "products": { ... },
    "categories": { ... },
    "orders": { ... }
  }
}
```

## Method 3: Using Newman (Command Line)

### Step 1: Install Newman
```bash
npm install -g newman
```

### Step 2: Run Collection with Reporting
```bash
# Basic run with JSON report
newman run postman-collection.json \
  --environment postman-environment.json \
  --reporters json \
  --reporter-json-export results-compilation.json

# Run with HTML report (more visual)
newman run postman-collection.json \
  --environment postman-environment.json \
  --reporters htmlextra \
  --reporter-htmlextra-export results-report.html
```

### Step 3: Parse Results
The generated files will contain all request/response data for analysis.

## Sample Compiled Output Structure

```json
{
  "reportGenerated": "2025-01-27T10:30:00.000Z",
  "summary": {
    "totalOperations": 4,
    "successfulOperations": 4
  },
  "results": {
    "LOGIN": {
      "timestamp": "2025-01-27T10:29:45.000Z",
      "operation": "LOGIN",
      "status": "SUCCESS", 
      "user": {
        "id": "3",
        "email": "manager@orderapp.com",
        "role": "manager"
      },
      "token_length": 123
    },
    "PRODUCTS": {
      "timestamp": "2025-01-27T10:29:46.000Z",
      "operation": "GET_PRODUCTS",
      "status": "SUCCESS",
      "count": 18,
      "products": [
        {
          "id": "18",
          "name": "Smart Phone - Local Brand",
          "price": 8999.0,
          "stockQuantity": 21
        }
        // ... more products
      ]
    },
    "CATEGORIES": {
      "timestamp": "2025-01-27T10:29:47.000Z", 
      "operation": "GET_CATEGORIES",
      "status": "SUCCESS",
      "count": 4,
      "categories": [
        {
          "id": "1",
          "name": "Electronics",
          "description": "Electronic gadgets and devices"
        }
        // ... more categories  
      ]
    },
    "ORDERS": {
      "timestamp": "2025-01-27T10:29:48.000Z",
      "operation": "GET_ORDERS", 
      "status": "SUCCESS",
      "count": 12,
      "orders": [
        {
          "id": "1",
          "referenceNumber": "ORD-2025-001",
          "status": "pending",
          "total": 1299.0,
          "orderType": "delivery",
          "itemCount": 3
        }
        // ... more orders
      ]
    }
  }
}
```

## Tips for Effective Compilation

1. **Use Collection Runner**: Most reliable method with automatic authentication handling
2. **Check Console Logs**: Postman console shows detailed compilation reports  
3. **Export Environment**: Save global variables containing all results
4. **Schedule Runs**: Use Newman with cron jobs for regular API monitoring
5. **Filter Results**: Modify test scripts to include/exclude specific data fields
6. **Error Handling**: Test scripts capture both success and error responses

## Troubleshooting

- **Authentication Issues**: Ensure login runs first and sets AUTH_TOKEN globally
- **Empty Results**: Check that test scripts are executing (view in Tests tab)
- **Missing Data**: Verify API responses match expected GraphQL schema
- **Permission Errors**: Confirm user has access to all queried resources

## Next Steps

- Set up automated monitoring with Newman + CI/CD
- Create data visualization dashboards from compiled results
- Implement alerting based on API response patterns
- Archive historical compilations for trend analysis