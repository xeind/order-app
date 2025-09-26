# frozen_string_literal: true

module Mutations
  class CreateCategory < BaseMutation
    description "Creates a new product category"

    argument :name, String, required: true
    argument :description, String, required: false

    field :category, Types::CategoryType, null: false
    field :errors, [ String ], null: false

    def resolve(name:, description: nil)
      JwtService.require_manager!(context)

      category = Category.new(name: name, description: description)

      if category.save
        {
          category: category,
          errors: []
        }
      else
        {
          category: nil,
          errors: category.errors.full_messages
        }
      end
    end
  end
end
