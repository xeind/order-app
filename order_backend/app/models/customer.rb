class Customer < ApplicationRecord
  has_many :orders, dependent: :destroy
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :mobile, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end
end
