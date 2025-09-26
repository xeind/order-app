# frozen_string_literal: true

class Types::OrderType < Types::BaseObject
  field :id, ID, null: false
  field :customer, Types::CustomerType, null: false
  field :voucher, Types::VoucherType, null: true
  field :reference_number, String, null: false
  field :status, String, null: false
  field :subtotal, Float, null: true
  field :discount_amount, Float, null: true
  field :total, Float, null: false
  field :order_type, String, null: true
  field :shipping_method, String, null: true
  field :payment_method, String, null: true
  field :delivery_address, String, null: true
  field :delivery_notes, String, null: true
  field :delivery_date_preference, GraphQL::Types::ISO8601DateTime, null: true
  field :order_items, [ Types::OrderItemType ], null: false
  field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

  def subtotal
    object.subtotal.to_f
  end

  def discount_amount
    object.discount_amount&.to_f || 0.0
  end

  def total
    object.total.to_f
  end
end
