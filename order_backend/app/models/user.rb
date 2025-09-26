# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: %w[manager staff] }

  def manager?
    role == "manager"
  end

  def staff?
    role == "staff"
  end
end
