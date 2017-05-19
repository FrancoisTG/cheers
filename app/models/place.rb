class Place < ApplicationRecord
  has_many :place_options, dependent: :destroy
  has_many :confirmations, dependent: :nullify
  has_many :hangouts, dependent: :nullify


  # geocoded_by :address
  # after_validation :geocode, if: :address?
end
