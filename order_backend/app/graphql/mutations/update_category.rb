# frozen_string_literal: true

module Mutations
  class UpdateCategory < BaseMutation
    description "Updates an existing product category"

    argument :id, ID, required: true
    argument :name, String, required: false
    argument :description, String, required: false

    field :category, Types::CategoryType, null: false
    field :errors, [ String ], null: false

    def resolve(id:, **attributes)
      JwtService.require_manager!(context)

      category = Category.find(id)

      if category.update(attributes.compact)
        {
          category: category,
          errors: []
        }
      else
        {
          category: category,
          errors: category.errors.full_messages
        }
      end
    end
  end
end
