# frozen_string_literal: true

class Mutations::LoginUser < Mutations::BaseMutation
  description "Login user"

  argument :email, String, required: true
  argument :password, String, required: true

  field :user, Types::UserType, null: true
  field :token, String, null: true
  field :errors, [ String ], null: true

  def resolve(email:, password:)
    user = User.find_by(email: email)

    if user&.authenticate(password)
      token = JwtService.encode(user_id: user.id)
      { user: user, token: token, errors: nil }
    else
      { user: nil, token: nil, errors: [ "Invalid email or password" ] }
    end
  end
end
