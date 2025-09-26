class AddDeliveryDetailsToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :delivery_address, :text
    add_column :orders, :delivery_notes, :text
    add_column :orders, :delivery_date_preference, :datetime
  end
end
