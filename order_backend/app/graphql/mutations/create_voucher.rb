# frozen_string_literal: true

module Mutations
  class CreateVoucher < BaseMutation
    argument :code, String, required: true
    argument :name, String, required: true
    argument :discount_type, String, required: true
    argument :discount_value, Float, required: true
    argument :expires_at, GraphQL::Types::ISO8601DateTime, required: false
    argument :usage_limit, Integer, required: false

    type Types::VoucherType

    def resolve(code:, name:, discount_type:, discount_value:, expires_at: nil, usage_limit: nil)
      voucher = Voucher.new(
        code: code,
        name: name,
        discount_type: discount_type,
        discount_value: discount_value,
        expires_at: expires_at,
        usage_limit: usage_limit
      )

      if voucher.save
        voucher
      else
        raise GraphQL::ExecutionError, voucher.errors.full_messages.join(", ")
      end
    end
  end
end
