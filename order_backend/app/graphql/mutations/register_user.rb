# frozen_string_literal: true

class Mutations::RegisterUser < Mutations::BaseMutation
  description "Register new user (manager only)"

  argument :username, String, required: true
  argument :email, String, required: true
  argument :password, String, required: true
  argument :role, String, required: true

  field :user, Types::UserType, null: true
  field :errors, [ String ], null: true

  def resolve(username:, email:, password:, role:)
    JwtService.require_manager!(context)

    user = User.new(
      username: username,
      email: email,
      password: password,
      role: role
    )

    if user.save
      { user: user, errors: nil }
    else
      { user: nil, errors: user.errors.full_messages }
    end
  end
end
