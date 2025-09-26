# frozen_string_literal: true

class Product < ApplicationRecord
  belongs_to :category
  has_many :order_items, dependent: :destroy
  has_one_attached :photo

  validates :name, presence: true
  validates :price, presence: true, numericality: {
    greater_than: 0
  }
  validates :stock_quantity, presence: true, numericality: {
    greater_than_or_equal_to: 0
  }
  validates :product_type, inclusion: { in: %w[physical digital] }

  def photo_url
    if photo.attached?
      Rails.application.routes.url_helpers.rails_blob_url(photo, host: Rails.application.config.action_controller.default_url_options[:host])
    else
      super
    end
  end
end
