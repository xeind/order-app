# Goshomo - Modern Point of Sale System

**Goshomo** *(Negosyo mo)* is a full-stack point-of-sale (POS) application built with Rails 7.1 API backend and Vue 3 frontend. It provides comprehensive order management, product catalog, customer management, and real-time cart functionality for retail businesses.

## Live Demo

- **Frontend**: [https://goshomo-frontend.vercel.app](https://goshomo-frontend.vercel.app)
- **Backend API**: [https://goshomo-backend.onrender.com](https://goshomo-backend.onrender.com)
- **GraphQL Playground**: [https://goshomo-backend.onrender.com/graphiql](https://goshomo-backend.onrender.com/graphiql)

## Features

### Core Functionality
- **User Authentication**: JWT-based auth with role management (Manager/Staff)
- **Product Management**: CRUD operations with categories and image uploads
- **Order Processing**: Real-time cart, checkout, and order tracking
- **Customer Management**: Customer profiles and order history
- **PDF Generation**: Invoice and receipt generation
- **Email Notifications**: Order confirmations and updates

### Security & Quality
- **Authentication**: JWT tokens with secure password hashing
- **File Upload Security**: Validated image uploads with ActiveStorage
- **CORS Configuration**: Proper cross-origin setup
- **Input Validation**: GraphQL schema validation and Rails validations
- **Code Quality**: RuboCop linting and Brakeman security scanning

### Business Features
- **Inventory Management**: Stock tracking and product variants
- **Order Status Tracking**: Pending → Confirmed → Delivered workflow
- **Customer Analytics**: Order history and customer insights
- **Receipt Generation**: Professional PDF receipts
- **Role-based Access**: Manager and Staff permission levels

## Architecture

### Backend (Rails 7.1 API)
- **Framework**: Ruby on Rails 7.1 with API-only configuration
- **Database**: SQLite3 (development) / PostgreSQL (production)
- **API**: GraphQL with Apollo Upload Server
- **Authentication**: JWT tokens with bcrypt password hashing
- **File Storage**: ActiveStorage for image uploads
- **Background Jobs**: Solid Queue for email processing

### Frontend (Vue 3)
- **Framework**: Vue 3 with Composition API
- **State Management**: Pinia for reactive state
- **Routing**: Vue Router 4
- **GraphQL Client**: Apollo Client with file upload support
- **Styling**: Tailwind CSS with HeadlessUI components
- **Build Tool**: Vite for fast development and builds

## Deployment

### Current Deployment Status: LIVE

The application is successfully deployed and running:

#### Backend Deployment (Render)
```bash
# Backend deployed at: https://goshomo-backend.onrender.com
# Build Command: ./bin/render-build.sh
# Start Command: bundle exec puma -C config/puma.rb
# Environment: Production with PostgreSQL
```

#### Frontend Deployment (Vercel)
```bash
# Frontend deployed at: https://goshomo-frontend.vercel.app
# Build Command: bun run build
# Framework: Vue.js
# Environment: Production with GraphQL endpoint
```

### Test Accounts
- **Manager**: `manager@orderapp.com` / `password123`
- **Staff**: `staff@orderapp.com` / `password123`

## Local Development Setup

### Prerequisites
- Ruby 3.2+
- Node.js 18+
- Bun (recommended) or npm
- Git

### Backend Setup
```bash
cd order_backend

# Install dependencies
bundle install

# Setup database
rails db:create db:migrate db:seed

# Run tests
rails test

# Start server
rails server
# or
bin/dev
```

### Frontend Setup
```bash
cd order_frontend

# Install dependencies
bun install

# Start development server
bun run dev

# Build for production
bun run build
```

## API Documentation

### GraphQL Schema
The API uses GraphQL with the following main types:

#### Mutations
- `authenticateUser(email, password)` - User login
- `createProduct(input)` - Add new product
- `updateProduct(id, input)` - Update product
- `deleteProduct(id)` - Remove product
- `createOrder(input)` - Place new order
- `updateOrderStatus(id, status)` - Update order status
- `createCustomer(input)` - Add customer

#### Queries
- `products` - List all products with filtering
- `product(id)` - Get single product
- `orders` - List orders with status filtering
- `order(id)` - Get single order with details
- `customers` - List customers
- `categories` - List product categories

### Authentication
All mutations require JWT authentication via `Authorization: Bearer <token>` header.

## Database Schema

### Core Models
- **User**: Authentication and role management
- **Product**: Catalog items with categories
- **Order**: Customer orders with line items
- **Customer**: Customer information and history
- **Category**: Product categorization

### Key Relationships
```ruby
User
├── has_many :orders (as creator)

Product
├── belongs_to :category
├── has_many :order_items
└── has_one_attached :image

Order
├── belongs_to :customer
├── belongs_to :user (creator)
└── has_many :order_items

Customer
├── has_many :orders
└── tracks order history
```

## Testing

### Backend Testing
```bash
cd order_backend

# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/product_test.rb

# Run with coverage
COVERAGE=true bin/rails test
```

### Code Quality
```bash
# Linting
bin/rubocop

# Security scan
bin/brakeman

# Auto-fix style issues
bin/rubocop -a
```

## Dependencies

### Backend Key Gems
- `rails ~> 7.1.3` - Web application framework
- `graphql ~> 2.0` - GraphQL API
- `jwt` - JSON Web Token authentication
- `bcrypt` - Password hashing
- `image_processing` - Image processing for uploads
- `solid_cache/queue/cable` - Rails performance stack
- `kamal` - Docker deployment

### Frontend Key Packages
- `vue ^3.5.21` - Progressive JavaScript framework
- `@apollo/client ^3.14.0` - GraphQL client
- `pinia ^3.0.3` - State management
- `vue-router 4` - Client-side routing
- `tailwindcss ^3.4.13` - Utility-first CSS
- `@headlessui/vue` - Unstyled UI components
- `jspdf ^3.0.3` - PDF generation

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow Rails conventions and RuboCop rules
- Use Vue 3 Composition API
- Write meaningful commit messages
- Add tests for new features

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions or support:
- Create an issue on GitHub
- Email: support@goshomo.com
- Documentation: Check the `/docs` folder for detailed guides

## Acknowledgments

- Built with Ruby on Rails and Vue.js
- UI components from HeadlessUI
- Icons from Heroicons
- Deployment on Render and Vercel

---

**Goshomo** *(Negosyo mo)* - Streamlining retail operations with modern web technology.