class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.string :name
      t.text :description
      t.decimal :price
      t.references :category, foreign_key: true
      t.string :product_type
      t.string :photo_url
      t.integer :stock_quantity

      t.timestamps
    end
  end
end
