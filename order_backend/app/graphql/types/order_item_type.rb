class Types::OrderItemType < Types::BaseObject
  field :id, ID, null: false
  field :order, Types::OrderType, null: false
  field :product, Types::ProductType, null: false
  field :quantity, Integer, null: false
  field :unit_price, Float, null: false
  field :total_price, Float, null: false
  field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
end
