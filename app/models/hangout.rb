class Hangout < ApplicationRecord
  belongs_to :user
  belongs_to :place, optional: true
  has_many :confirmations
  has_many :place_options

  validates :title, presence: true
  validates :date, presence: true
  validates :category, presence: true
  validates :status, presence: true



  geocoded_by :center_address
  after_validation :geocode, if: :center_address?
end
