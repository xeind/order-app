# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    # Authentication mutations
    field :login_user, mutation: Mutations::LoginUser
    field :register_user, mutation: Mutations::RegisterUser

    # Category mutations
    field :create_category, mutation: Mutations::CreateCategory
    field :update_category, mutation: Mutations::UpdateCategory
    field :delete_category, mutation: Mutations::DeleteCategory

    # Product mutations
    field :create_product, mutation: Mutations::CreateProduct

    field :update_product, Types::ProductType, null: false do
      argument :id, ID, required: true
      argument :name, String, required: false
      argument :description, String, required: false
      argument :price, Float, required: false
      argument :category_id, ID, required: false
      argument :product_type, String, required: false
      argument :photo_url, String, required: false
      argument :stock_quantity, Integer, required: false
    end

    def update_product(id:, **attributes)
      JwtService.require_manager!(context)
      product = Product.find(id)

      # Handle photo_url separately to allow setting it to null
      if attributes.key?(:photo_url)
        photo_url = attributes.delete(:photo_url)
        product.photo_url = photo_url
      end

      # Filter out nil values and empty strings for optional fields
      filtered_attributes = attributes.compact.reject { |k, v| v == "" }

      # Update other attributes
      if filtered_attributes.any?
        product.update!(filtered_attributes)
      end

      product
    rescue ActiveRecord::RecordInvalid => e
      raise GraphQL::ExecutionError, e.record.errors.full_messages.join(", ")
    rescue ActiveRecord::RecordNotFound => e
      raise GraphQL::ExecutionError, "Product not found"
    end

    field :delete_product, Boolean, null: false do
      argument :id, ID, required: true
    end

    def delete_product(id:)
      JwtService.require_manager!(context)
      product = Product.find(id)
      product.destroy!
      true
    rescue ActiveRecord::RecordNotFound
      false
    end

    field :create_order, Types::OrderType, null: false do
      argument :customer_id, ID, required: true
      argument :items, [ Types::OrderItemInputType ], required: true
      argument :order_type, String, required: false
      argument :shipping_method, String, required: false
      argument :payment_method, String, required: true
      argument :voucher_code, String, required: false
      argument :delivery_address, String, required: false
      argument :delivery_notes, String, required: false
      argument :delivery_date_preference, GraphQL::Types::ISO8601DateTime, required: false
    end

    def create_order(customer_id:, items:, payment_method:, order_type: "online", shipping_method: nil, voucher_code: nil, delivery_address: nil, delivery_notes: nil, delivery_date_preference: nil)
      JwtService.require_authentication!(context)

      ActiveRecord::Base.transaction do
        # Validate stock availability for all items first
        items.each do |item_input|
          product = Product.find(item_input[:product_id])
          if item_input[:quantity] > product.stock_quantity
            raise GraphQL::ExecutionError, "Insufficient stock for #{product.name}. Available: #{product.stock_quantity}, Requested: #{item_input[:quantity]}"
          end
        end

        # Calculate subtotal
        subtotal = items.sum { |item| item[:quantity] * item[:unit_price] }

        # Calculate initial subtotal from input
        subtotal = items.sum { |item| item[:quantity] * item[:unit_price] }

        order = Order.new(
          customer_id: customer_id,
          status: "pending",
          order_type: order_type,
          shipping_method: shipping_method,
          payment_method: payment_method,
          delivery_address: delivery_address,
          delivery_notes: delivery_notes,
          delivery_date_preference: delivery_date_preference,
          total: subtotal  # Set total initially to subtotal
        )

        # Skip automatic total calculation during initial save
        order.skip_total_calculation = true

        # Apply voucher if provided
        if voucher_code.present?
          voucher = Voucher.find_by(code: voucher_code.upcase.strip)
          if voucher && voucher.valid_for_use?
            order.voucher = voucher
            discount_amount = voucher.calculate_discount(subtotal)
            order.discount_amount = discount_amount
            order.total = subtotal - discount_amount
          else
            raise GraphQL::ExecutionError, "Voucher not found or invalid"
          end
        end

        # Save order first
        order.save!

        # Create order items (stock will be decremented automatically via callbacks)
        items.each do |item_input|
          OrderItem.create!(
            order: order,
            product_id: item_input[:product_id],
            quantity: item_input[:quantity],
            unit_price: item_input[:unit_price]
          )
        end

        # Now recalculate total based on actual order items and save
        order.skip_total_calculation = false
        order.send(:calculate_total)
        order.save!

        # Mark voucher as used
        order.voucher&.use!

        # Send order confirmation email
        begin
          OrderMailer.order_confirmation(order).deliver_now
        rescue => e
          # Log the error but don't fail the order creation
          Rails.logger.error "Failed to send order confirmation email: #{e.message}"
        end

        order
      end
    rescue ActiveRecord::RecordInvalid => e
      raise GraphQL::ExecutionError, e.record.errors.full_messages.join(", ")
    end

    field :update_order_status, Types::OrderType, null: false do
      argument :id, ID, required: true
      argument :status, String, required: true
    end

    def update_order_status(id:, status:)
      JwtService.require_manager!(context)
      order = Order.find(id)
      order.update!(status: status)
      order
    end

    field :add_order_item, Types::OrderItemType, null: false do
      argument :order_id, ID, required: true
      argument :product_id, ID, required: true
      argument :quantity, Integer, required: true
    end

    def add_order_item(order_id:, product_id:, quantity:)
      JwtService.require_manager!(context)
      product = Product.find(product_id)
      order_item = OrderItem.create!(
        order_id: order_id,
        product_id: product_id,
        quantity: quantity,
        unit_price: product.price
      )

      # Update order total
      order = Order.find(order_id)
      order.update!(total: order.order_items.sum(:total_price))

      order_item
    end

    # Voucher mutations
    field :create_voucher, Types::VoucherType, null: false do
      argument :code, String, required: true
      argument :name, String, required: true
      argument :discount_type, String, required: true
      argument :discount_value, Float, required: true
      argument :expires_at, GraphQL::Types::ISO8601DateTime, required: false
      argument :usage_limit, Integer, required: false
    end

    def create_voucher(code:, name:, discount_type:, discount_value:, expires_at: nil, usage_limit: nil)
      JwtService.require_manager!(context)
      voucher = Voucher.new(
        code: code,
        name: name,
        discount_type: discount_type,
        discount_value: discount_value,
        expires_at: expires_at,
        usage_limit: usage_limit
      )

      if voucher.save
        voucher
      else
        raise GraphQL::ExecutionError, voucher.errors.full_messages.join(", ")
      end
    end

    # Customer mutations
    field :create_customer, Types::CustomerType, null: false do
      argument :first_name, String, required: true
      argument :last_name, String, required: true
      argument :email, String, required: true
      argument :mobile, String, required: true
    end

    def create_customer(first_name:, last_name:, email:, mobile:)
      JwtService.require_authentication!(context)
      customer = Customer.new(
        first_name: first_name,
        last_name: last_name,
        email: email,
        mobile: mobile
      )

      if customer.save
        customer
      else
        raise GraphQL::ExecutionError, customer.errors.full_messages.join(", ")
      end
    end
  end
end
