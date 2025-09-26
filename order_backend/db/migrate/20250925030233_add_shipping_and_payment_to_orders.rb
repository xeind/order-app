class AddShippingAndPaymentToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :shipping_method, :string
    add_column :orders, :payment_method, :string
  end
end
