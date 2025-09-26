class CreateCustomers < ActiveRecord::Migration[7.1]
  def change
    create_table :customers do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :mobile
      t.text :address_text

      t.timestamps
    end
  end
end
