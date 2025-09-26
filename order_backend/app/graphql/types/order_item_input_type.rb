# frozen_string_literal: true

class Types::OrderItemInputType < Types::BaseInputObject
  argument :product_id, ID, required: true
  argument :quantity, Integer, required: true
  argument :unit_price, Float, required: true
end
