class Types::CustomerType < Types::BaseObject
  field :id, ID, null: false
  field :first_name, String, null: false
  field :last_name, String, null: false
  field :email, String, null: false
  field :mobile, String, null: false
  field :address_text, String, null: true
  field :full_name, String, null: false
  field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

  def full_name
    "#{object.first_name} #{object.last_name}"
  end
end
