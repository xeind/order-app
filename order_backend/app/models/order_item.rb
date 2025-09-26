class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :quantity, presence: true, numericality: {
    greater_than: 0
  }

  validates :unit_price, presence: true, numericality: {
    greater_than: 0
  }

  # Stock validation
  validate :sufficient_stock, on: :create

  before_save :calculate_total_price
  after_create :decrement_product_stock
  after_destroy :increment_product_stock

  private

  def calculate_total_price
    self.total_price = quantity * unit_price
  end

  def sufficient_stock
    return unless product && quantity

    if quantity > product.stock_quantity
      errors.add(:quantity, "cannot exceed available stock (#{product.stock_quantity})")
    end
  end

  def decrement_product_stock
    product.with_lock do
      if product.stock_quantity >= quantity
        product.update_columns(stock_quantity: product.stock_quantity - quantity)
      else
        raise ActiveRecord::RecordInvalid.new(self)
      end
    end
  end

  def increment_product_stock
    product.with_lock do
      product.update_columns(stock_quantity: product.stock_quantity + quantity)
    end
  end
end
