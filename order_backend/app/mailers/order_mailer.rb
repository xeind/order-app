# frozen_string_literal: true

class OrderMailer < ApplicationMailer
  def order_confirmation(order)
    @order = order
    @customer = order.customer
    @order_items = order.order_items.includes(:product)
    @subtotal = order.subtotal
    @discount_amount = order.discount_amount || 0
    @total = order.total

    mail(
      to: @customer.email,
      subject: "Order Confirmation - #{@order.reference_number}"
    )
  end
end
