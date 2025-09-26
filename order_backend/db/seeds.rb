# frozen_string_literal: true

# Clear existing data
OrderItem.delete_all
Order.delete_all
Product.delete_all
Category.delete_all
Customer.delete_all
User.delete_all
Voucher.delete_all

# Create initial manager user
User.create!(
  username: "manager",
  email: "manager@orderapp.com",
  password: "password123",
  role: "manager"
)

# Create initial staff user
User.create!(
  username: "staff1",
  email: "staff@orderapp.com",
  password: "password123",
  role: "staff"
)

# Create Categories
electronics = Category.create!(name: "Electronics", description: "Electronic devices and gadgets")
food = Category.create!(name: "Food & Beverages", description: "Filipino food and drinks")
clothing = Category.create!(name: "Clothing", description: "Filipino fashion and apparel")
beauty = Category.create!(name: "Beauty & Personal Care", description: "Skincare, cosmetics and personal items")

# Create Products - Philippines-based
# Electronics Category
Product.create!(
  name: "Smart Phone - Local Brand",
  description: "Filipino-made smartphone with dual SIM support",
  price: 8999.00,
  category: electronics,
  product_type: "physical",
  stock_quantity: 25,
  photo_url: "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=200"
)

Product.create!(
  name: "Bluetooth Speaker",
  description: "Portable speaker perfect for Filipino parties and gatherings",
  price: 2499.00,
  category: electronics,
  product_type: "physical",
  stock_quantity: 40,
  photo_url: "https://images.unsplash.com/photo-1589003077984-894e133dabab?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=200"
)

Product.create!(
  name: "Power Bank - 20000mAh",
  description: "High capacity power bank for long Filipino commutes",
  price: 1299.00,
  category: electronics,
  product_type: "physical",
  stock_quantity: 60,
  photo_url: "https://images.unsplash.com/photo-1609091839311-d5365f9ff1c5?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=200"
)

Product.create!(
  name: "Wireless Earphones",
  description: "TWS earphones perfect for listening to OPM songs",
  price: 1899.00,
  category: electronics,
  product_type: "physical",
  stock_quantity: 35,
  photo_url: "https://images.unsplash.com/photo-1590658165737-15a047b7b4f4?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=200"
)

# Food & Beverages Category
Product.create!(
  name: "Dried Mango",
  description: "Premium Cebu dried mango strips",
  price: 180.00,
  category: food,
  product_type: "physical",
  stock_quantity: 100,
  photo_url: "https://images.unsplash.com/photo-1587486913049-53fc88980cfc?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=200"
)

Product.create!(
  name: "Barako Coffee Beans",
  description: "Authentic Kapeng Barako from Batangas - 250g",
  price: 320.00,
  category: food,
  product_type: "physical",
  stock_quantity: 80,
  photo_url: "https://images.unsplash.com/photo-1447933601403-0c6688de566e?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=200"
)

Product.create!(
  name: "Chicharon",
  description: "Crispy pork rinds - classic Filipino snack",
  price: 120.00,
  category: food,
  product_type: "physical",
  stock_quantity: 75,
  photo_url: "https://images.unsplash.com/photo-1594756202469-556d1cf96b43?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=200"
)

Product.create!(
  name: "Coconut Water",
  description: "Fresh buko juice in tetra pack - 1L",
  price: 85.00,
  category: food,
  product_type: "physical",
  stock_quantity: 120,
  photo_url: "https://images.unsplash.com/photo-1564759224907-65ba80d50e6e?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=200"
)

Product.create!(
  name: "Taho Mix",
  description: "Complete taho mix kit with arnibal and sago",
  price: 150.00,
  category: food,
  product_type: "physical",
  stock_quantity: 45,
  photo_url: "https://images.unsplash.com/photo-1563805042-7684c019e1cb?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=200"
)

# Clothing Category
Product.create!(
  name: "Barong Tagalog",
  description: "Traditional Filipino formal shirt - Jusi fabric",
  price: 2500.00,
  category: clothing,
  product_type: "physical",
  stock_quantity: 15,
  photo_url: "https://images.unsplash.com/photo-1622519407650-3df9883f76a3?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=200"
)

Product.create!(
  name: "Filipiniana Dress",
  description: "Modern Filipiniana dress for special occasions",
  price: 3200.00,
  category: clothing,
  product_type: "physical",
  stock_quantity: 12,
  photo_url: "https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=200"
)

Product.create!(
  name: "Malong",
  description: "Traditional Mindanao tube garment - multicolor",
  price: 450.00,
  category: clothing,
  product_type: "physical",
  stock_quantity: 30,
  photo_url: "https://images.unsplash.com/photo-1582639510494-c80b5de9f148?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=200"
)

Product.create!(
  name: "Sando - Local Brand",
  description: "Cotton tank top from Filipino clothing brand",
  price: 299.00,
  category: clothing,
  product_type: "physical",
  stock_quantity: 85,
  photo_url: "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=200"
)

# Beauty & Personal Care Category
Product.create!(
  name: "Kojic Soap",
  description: "Authentic kojic acid soap for skin whitening",
  price: 65.00,
  category: beauty,
  product_type: "physical",
  stock_quantity: 150,
  photo_url: "https://images.unsplash.com/photo-1556228453-efd6c1ff04f6?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=200"
)

Product.create!(
  name: "Gugo Shampoo",
  description: "Natural gugo extract shampoo for strong hair",
  price: 180.00,
  category: beauty,
  product_type: "physical",
  stock_quantity: 90,
  photo_url: "https://images.unsplash.com/photo-1571781926291-c477ebfd024b?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=200"
)

Product.create!(
  name: "Virgin Coconut Oil",
  description: "100% pure VCO for skin and hair - 100ml",
  price: 250.00,
  category: beauty,
  product_type: "physical",
  stock_quantity: 70,
  photo_url: "https://images.unsplash.com/photo-1615184158932-8bb5ac3e4e45?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=200"
)

Product.create!(
  name: "Sampaguita Perfume",
  description: "Filipino-inspired sampaguita scented perfume",
  price: 899.00,
  category: beauty,
  product_type: "physical",
  stock_quantity: 25,
  photo_url: "https://images.unsplash.com/photo-1541643600914-78b084683601?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=200"
)

# Create Filipino Customers with Philippine mobile numbers
Customer.create!(
  first_name: "Maria",
  last_name: "Santos",
  email: "maria.santos@gmail.com",
  mobile: "+63917-123-4567"
)

Customer.create!(
  first_name: "Juan",
  last_name: "Cruz",
  email: "juan.cruz@yahoo.com",
  mobile: "+63906-987-6543"
)

Customer.create!(
  first_name: "Ana",
  last_name: "Reyes",
  email: "ana.reyes@gmail.com",
  mobile: "+63915-555-0123"
)

Customer.create!(
  first_name: "Jose",
  last_name: "Garcia",
  email: "jose.garcia@hotmail.com",
  mobile: "+63928-444-7890"
)

Customer.create!(
  first_name: "Rosa",
  last_name: "Dela Cruz",
  email: "rosa.delacruz@gmail.com",
  mobile: "+63912-333-2468"
)

Customer.create!(
  first_name: "Miguel",
  last_name: "Villanueva",
  email: "miguel.villanueva@yahoo.com",
  mobile: "+63920-111-9876"
)

# Create test vouchers
Voucher.create!(
  code: "WELCOME10",
  name: "Welcome 10% Off",
  discount_type: "percentage",
  discount_value: 10,
  usage_limit: 100,
  expires_at: 1.month.from_now
)

Voucher.create!(
  code: "SAVE500",
  name: "Save ₱500",
  discount_type: "fixed_amount",
  discount_value: 500,
  usage_limit: 50,
  expires_at: 2.weeks.from_now
)

Voucher.create!(
  code: "FIRSTBUY15",
  name: "First-time Buyer 15% Off",
  discount_type: "percentage",
  discount_value: 15,
  usage_limit: 200
)

Voucher.create!(
  code: "FREEBIE",
  name: "Free Shipping Voucher",
  discount_type: "fixed_amount",
  discount_value: 250,
  usage_limit: nil  # Unlimited usage
)

# Create sample orders with vouchers
customers = Customer.all
products = Product.all
vouchers = Voucher.all

puts "Creating sample orders with vouchers..."

# Order 1: Maria Santos - WELCOME10 voucher (10% off)
maria = customers.first
phone = products.find_by(name: "Smart Phone - Local Brand")
earphones = products.find_by(name: "Wireless Earphones")

order1 = Order.new(
  customer: maria,
  status: "pending",
  order_type: "online",
  shipping_method: "standard",
  payment_method: "gcash",
  voucher: vouchers.find_by(code: "WELCOME10"),
  delivery_address: "Unit 12B, Tower 1, Residences at Commonwealth, Quezon City, Metro Manila 1121 (Near Ever Gotesco Commonwealth)",
  delivery_notes: "Please call when near the building. Guard requires ID.",
  delivery_date_preference: 1.day.from_now,
  total: 1 # Temporary value to pass validation
)
order1.skip_total_calculation = true
order1.save!

OrderItem.create!(
  order: order1,
  product: phone,
  quantity: 1,
  unit_price: phone.price
)

OrderItem.create!(
  order: order1,
  product: earphones,
  quantity: 2,
  unit_price: earphones.price
)

# Calculate totals for order1
subtotal1 = order1.order_items.sum { |item| item.quantity * item.unit_price }
discount1 = order1.voucher.calculate_discount(subtotal1)
order1.update!(
  discount_amount: discount1,
  total: subtotal1 - discount1
)

# Order 2: Juan Cruz - SAVE500 voucher (₱500 off)
juan = customers.second
barong = products.find_by(name: "Barong Tagalog")
perfume = products.find_by(name: "Sampaguita Perfume")

order2 = Order.new(
  customer: juan,
  status: "confirmed",
  order_type: "online",
  shipping_method: "express",
  payment_method: "cod",
  voucher: vouchers.find_by(code: "SAVE500"),
  delivery_address: "456 Rizal Street, Poblacion, Makati City 1210",
  delivery_notes: "Office delivery - ask for Juan at reception",
  delivery_date_preference: 2.days.from_now,
  total: 1 # Temporary value to pass validation
)
order2.skip_total_calculation = true
order2.save!

OrderItem.create!(
  order: order2,
  product: barong,
  quantity: 1,
  unit_price: barong.price
)

OrderItem.create!(
  order: order2,
  product: perfume,
  quantity: 1,
  unit_price: perfume.price
)

# Calculate totals for order2
subtotal2 = order2.order_items.sum { |item| item.quantity * item.unit_price }
discount2 = order2.voucher.calculate_discount(subtotal2)
order2.update!(
  discount_amount: discount2,
  total: subtotal2 - discount2
)

# Order 3: Ana Reyes - FIRSTBUY15 voucher (15% off)
ana = customers.third
speaker = products.find_by(name: "Bluetooth Speaker")
mango = products.find_by(name: "Dried Mango")
coffee = products.find_by(name: "Barako Coffee Beans")

order3 = Order.new(
  customer: ana,
  status: "completed",
  order_type: "online",
  shipping_method: "standard",
  payment_method: "bank_transfer",
  voucher: vouchers.find_by(code: "FIRSTBUY15"),
  delivery_address: "789 Bonifacio Drive, Port Area, Manila 1018 (Near Manila Ocean Park)",
  delivery_notes: "3rd floor, blue gate. Ring doorbell twice.",
  delivery_date_preference: Date.current,
  total: 1 # Temporary value to pass validation
)
order3.skip_total_calculation = true
order3.save!

OrderItem.create!(
  order: order3,
  product: speaker,
  quantity: 1,
  unit_price: speaker.price
)

OrderItem.create!(
  order: order3,
  product: mango,
  quantity: 3,
  unit_price: mango.price
)

OrderItem.create!(
  order: order3,
  product: coffee,
  quantity: 2,
  unit_price: coffee.price
)

# Calculate totals for order3
subtotal3 = order3.order_items.sum { |item| item.quantity * item.unit_price }
discount3 = order3.voucher.calculate_discount(subtotal3)
order3.update!(
  discount_amount: discount3,
  total: subtotal3 - discount3
)

# Order 4: Jose Garcia - FREEBIE voucher (₱250 off)
jose = customers.fourth
powerbank = products.find_by(name: "Power Bank - 20000mAh")
soap = products.find_by(name: "Kojic Soap")
oil = products.find_by(name: "Virgin Coconut Oil")

order4 = Order.new(
  customer: jose,
  status: "pending",
  order_type: "online",
  shipping_method: "standard",
  payment_method: "credit_card",
  voucher: vouchers.find_by(code: "FREEBIE"),
  delivery_address: "321 EDSA Corner Shaw Boulevard, Mandaluyong City 1552",
  delivery_notes: "Mall pickup - SM Megamall, Customer Service Counter",
  delivery_date_preference: 3.days.from_now,
  total: 1 # Temporary value to pass validation
)
order4.skip_total_calculation = true
order4.save!

OrderItem.create!(
  order: order4,
  product: powerbank,
  quantity: 1,
  unit_price: powerbank.price
)

OrderItem.create!(
  order: order4,
  product: soap,
  quantity: 5,
  unit_price: soap.price
)

OrderItem.create!(
  order: order4,
  product: oil,
  quantity: 2,
  unit_price: oil.price
)

# Calculate totals for order4
subtotal4 = order4.order_items.sum { |item| item.quantity * item.unit_price }
discount4 = order4.voucher.calculate_discount(subtotal4)
order4.update!(
  discount_amount: discount4,
  total: subtotal4 - discount4
)

# Order 5: In-store order without voucher
rosa = customers.fifth
filipiniana = products.find_by(name: "Filipiniana Dress")
coconut = products.find_by(name: "Coconut Water")

order5 = Order.new(
  customer: rosa,
  status: "completed",
  order_type: "in-store",
  payment_method: "cash",
  total: 1 # Temporary value to pass validation
)
order5.skip_total_calculation = true
order5.save!

OrderItem.create!(
  order: order5,
  product: filipiniana,
  quantity: 1,
  unit_price: filipiniana.price
)

OrderItem.create!(
  order: order5,
  product: coconut,
  quantity: 2,
  unit_price: coconut.price
)

# Calculate totals for order5
subtotal5 = order5.order_items.sum { |item| item.quantity * item.unit_price }
order5.update!(
  discount_amount: 0,
  total: subtotal5
)

# Order 6: Miguel Villanueva - Cancelled order with voucher
miguel = customers.last
malong = products.find_by(name: "Malong")
chicharon = products.find_by(name: "Chicharon")

order6 = Order.new(
  customer: miguel,
  status: "cancelled",
  order_type: "online",
  shipping_method: "express",
  payment_method: "gcash",
  voucher: vouchers.find_by(code: "WELCOME10"),
  delivery_address: "555 Katipunan Avenue, Loyola Heights, Quezon City 1108",
  delivery_notes: "University area - call when arrived",
  total: 1 # Temporary value to pass validation
)
order6.skip_total_calculation = true
order6.save!

OrderItem.create!(
  order: order6,
  product: malong,
  quantity: 2,
  unit_price: malong.price
)

OrderItem.create!(
  order: order6,
  product: chicharon,
  quantity: 4,
  unit_price: chicharon.price
)

# Calculate totals for order6
subtotal6 = order6.order_items.sum { |item| item.quantity * item.unit_price }
discount6 = order6.voucher.calculate_discount(subtotal6)
order6.update!(
  discount_amount: discount6,
  total: subtotal6 - discount6
)

puts "Seeded database with Philippines-based data:"
puts "- #{User.count} users (manager: manager@orderapp.com, staff: staff@orderapp.com)"
puts "- #{Category.count} categories"
puts "- #{Product.count} products"
puts "- #{Customer.count} customers"
puts "- #{Voucher.count} vouchers"
puts "- #{Order.count} sample orders with voucher information"
