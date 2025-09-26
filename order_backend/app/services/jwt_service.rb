# frozen_string_literal: true

class JwtService
  SECRET_KEY = Rails.application.secret_key_base.to_s

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end

  def self.current_user(context)
    return nil unless context[:current_user]

    context[:current_user]
  end

  def self.require_authentication!(context)
    raise GraphQL::ExecutionError, "Authentication required" unless current_user(context)
  end

  def self.require_manager!(context)
    user = current_user(context)
    raise GraphQL::ExecutionError, "Manager access required" unless user&.manager?
  end
end
