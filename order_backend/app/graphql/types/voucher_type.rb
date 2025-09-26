# frozen_string_literal: true

module Types
  class VoucherType < Types::BaseObject
    field :id, ID, null: false
    field :code, String, null: false
    field :name, String, null: false
    field :discount_type, String, null: false
    field :discount_value, Float, null: false
    field :expires_at, GraphQL::Types::ISO8601DateTime, null: true
    field :active, Boolean, null: false
    field :usage_limit, Integer, null: true
    field :usage_count, Integer, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    def discount_value
      object.discount_value.to_f
    end
  end
end
