# frozen_string_literal: true

class Order < ApplicationRecord
  attr_accessor :skip_total_calculation

  belongs_to :customer
  belongs_to :voucher, optional: true
  has_many :order_items, dependent: :destroy

  validates :reference_number, presence: true, uniqueness: true
  validates :status, presence: true
  validates :total, presence: true, numericality: { greater_than: 0 }
  validates :payment_method, presence: true
  validates :discount_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_validation :generate_reference_number, on: :create
  before_validation :calculate_discount_amount, unless: :skip_total_calculation
  after_update :handle_status_change

  def subtotal
    order_items.sum { |item| item.quantity * item.unit_price }
  end

  def apply_voucher(voucher_code)
    voucher = Voucher.find_by(code: voucher_code.upcase.strip)
    return { success: false, message: "Voucher not found" } unless voucher
    return { success: false, message: "Voucher is expired or inactive" } unless voucher.valid_for_use?

    self.voucher = voucher
    calculate_discount_amount
    { success: true, message: "Voucher applied successfully", discount: discount_amount }
  end

  def remove_voucher
    self.voucher = nil
    self.discount_amount = 0
    calculate_total
  end

  private

  def generate_reference_number
    self.reference_number ||= "ORD-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
  end

  def calculate_discount_amount
    if voucher.present?
      self.discount_amount = voucher.calculate_discount(subtotal)
    else
      self.discount_amount = 0
    end
    calculate_total
  end

  def calculate_total
    self.total = subtotal - (discount_amount || 0)
  end

  def handle_status_change
    if saved_change_to_status? && status == "cancelled" && status_before_last_save != "cancelled"
      restore_product_stock
    end
  end

  def restore_product_stock
    order_items.each do |order_item|
      order_item.product.with_lock do
        order_item.product.update_columns(
          stock_quantity: order_item.product.stock_quantity + order_item.quantity
        )
      end
    end
  end
end
