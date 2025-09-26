class AddVoucherToOrders < ActiveRecord::Migration[7.1]
  def change
    add_reference :orders, :voucher, foreign_key: true
    add_column :orders, :discount_amount, :decimal
  end
end
