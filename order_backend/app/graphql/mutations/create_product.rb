# frozen_string_literal: true

module Mutations
  class CreateProduct < BaseMutation
    description "Creates a new product with optional photo upload"

    argument :name, String, required: true
    argument :description, String, required: false
    argument :price, Float, required: true
    argument :category_id, ID, required: true
    argument :product_type, String, required: false

    argument :photo_url, String, required: false
    argument :stock_quantity, Integer, required: true

    field :product, Types::ProductType, null: false
    field :errors, [ String ], null: false

    def resolve(name:, price:, category_id:, stock_quantity:, description: nil, product_type: "physical", photo_url: nil)
      JwtService.require_manager!(context)

      product = Product.new(
        name: name,
        description: description,
        price: price,
        category_id: category_id,
        product_type: product_type,
        stock_quantity: stock_quantity
      )

      if photo_url.present?
        product.photo_url = photo_url
      end

      if product.save
        {
          product: product,
          errors: []
        }
      else
        {
          product: nil,
          errors: product.errors.full_messages
        }
      end
    end
  end
end
