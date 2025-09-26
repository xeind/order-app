# frozen_string_literal: true

class Voucher < ApplicationRecord
  has_many :orders, dependent: :nullify

  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :discount_type, presence: true, inclusion: { in: %w[percentage fixed_amount] }
  validates :discount_value, presence: true, numericality: { greater_than: 0 }
  validates :usage_limit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :usage_count, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :unexpired, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :available, -> { active.unexpired }

  before_validation :normalize_code
  before_validation :set_defaults, on: :create

  def valid_for_use?
    return false unless active? && !expired?
    return true if usage_limit.nil?

    usage_count < usage_limit
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def calculate_discount(subtotal)
    return 0 unless valid_for_use?

    case discount_type
    when "percentage"
      (subtotal * discount_value / 100).round(2)
    when "fixed_amount"
      [ discount_value, subtotal ].min.round(2)
    else
      0
    end
  end

  def use!
    increment!(:usage_count)
  end

  private

  def normalize_code
    self.code = code&.strip&.upcase
  end

  def set_defaults
    self.active = true if active.nil?
    self.usage_count = 0 if usage_count.nil?
  end
end
