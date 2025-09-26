class Types::ProductType < Types::BaseObject
  field :id, ID, null: false
  field :name, String, null: false
  field :description, String, null: true
  field :price, Float, null: false
  field :category, Types::CategoryType, null: false
  field :product_type, String, null: true
  field :photo_url, String, null: true
  field :stock_quantity, Integer, null: false
  field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
end
