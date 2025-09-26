# frozen_string_literal: true

class Types::AuthPayloadType < Types::BaseObject
  field :token, String, null: false
  field :user, Types::UserType, null: false
end
