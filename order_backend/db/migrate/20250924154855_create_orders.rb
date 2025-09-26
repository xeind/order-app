class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.references :customer, foreign_key: true
      t.string :reference_number
      t.string :status
      t.decimal :subtotal
      t.decimal :total
      t.string :order_type

      t.timestamps
    end
  end
end
