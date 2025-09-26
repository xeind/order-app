# frozen_string_literal: true

module Mutations
  class DeleteCategory < BaseMutation
    description "Deletes a product category"

    argument :id, ID, required: true

    field :success, Boolean, null: false
    field :errors, [ String ], null: false

    def resolve(id:)
      JwtService.require_manager!(context)

      category = Category.find(id)

      # Check if category has products
      if category.products.exists?
        {
          success: false,
          errors: [ "Cannot delete category with existing products. Please move or delete all products first." ]
        }
      elsif category.destroy
        {
          success: true,
          errors: []
        }
      else
        {
          success: false,
          errors: category.errors.full_messages
        }
      end
    rescue ActiveRecord::RecordNotFound
      {
        success: false,
        errors: [ "Category not found" ]
      }
    end
  end
end
