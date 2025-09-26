class CreateVouchers < ActiveRecord::Migration[7.1]
  def change
    create_table :vouchers do |t|
      t.string :code
      t.string :name
      t.string :discount_type
      t.decimal :discount_value
      t.datetime :expires_at
      t.boolean :active
      t.integer :usage_limit
      t.integer :usage_count

      t.timestamps
    end
    add_index :vouchers, :code, unique: true
  end
end
