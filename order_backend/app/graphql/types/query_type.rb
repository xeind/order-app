# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :node, Types::NodeType, null: true, description: "Fetches an object given its ID." do
      argument :id, ID, required: true, description: "ID of the object."
    end

    def node(id:)
      context.schema.object_from_id(id, context)
    end

    field :nodes, [ Types::NodeType, null: true ], null: true, description: "Fetches a list of objects given a list of IDs." do
      argument :ids, [ ID ], required: true, description: "IDs of the objects."
    end

    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    field :products, [ Types::ProductType ], null: false do
      argument :category_id, ID, required: false
      argument :search, String, required: false
    end

    def products(category_id: nil, search: nil)
      require_authentication!
      products = Product.includes(:category)
      products = products.where(category_id: category_id) if category_id
      products = products.where("LOWER(name) LIKE ?", "%#{search.downcase}%") if search
      products
    end

    field :categories, [ Types::CategoryType ], null: false
    def categories
      require_authentication!
      Category.all
    end

    field :customers, [ Types::CustomerType ], null: false do
      argument :search, String, required: false
    end

    def customers(search: nil)
      require_authentication!
      if search
        Customer.where("LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(email) LIKE ? OR LOWER(mobile) LIKE ?",
                       "%#{search.downcase}%", "%#{search.downcase}%", "%#{search.downcase}%", "%#{search.downcase}%")
      else
        Customer.all
      end
    end

    field :orders, [ Types::OrderType ], null: false do
      argument :status, String, required: false
    end

    def orders(status: nil)
      require_authentication!
      orders = Order.includes(:customer, :order_items, :voucher)
      orders = orders.where(status: status) if status
      orders.order(created_at: :desc)
    end

    field :vouchers, [ Types::VoucherType ], null: false do
      argument :active_only, Boolean, required: false, default_value: true
    end

    def vouchers(active_only: true)
      require_authentication!
      vouchers = Voucher.all
      vouchers = vouchers.available if active_only
      vouchers.order(:name)
    end

    field :validate_voucher, Types::VoucherType, null: true do
      argument :code, String, required: true
      argument :subtotal, Float, required: true
    end

    def validate_voucher(code:, subtotal:)
      require_authentication!
      voucher = Voucher.find_by(code: code.upcase.strip)
      return nil unless voucher&.valid_for_use?

      voucher
    end
  end
end
