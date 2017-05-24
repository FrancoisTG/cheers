class Hangout < ApplicationRecord
  belongs_to :user
  belongs_to :place, optional: true
  has_many :confirmations
  has_many :place_options

  validates :title, presence: true, length: { maximum: 60, message: "Maximum 60 characters" }
  validates :date, presence: true, inclusion: { in: (Date.today..Date.today+10.years), message: "Can not be in the past" }
  validates :category, presence: true
  validates :status, presence: true


  scope :cancelled, -> { where(status: "cancelled") }
  scope :valid, -> { where.not(status: "cancelled") }
  scope :vote_now, -> { where(status: "vote_on_going") }
  scope :vote_finished, -> { where(status: "result") }
  scope :past_hangout, ->(time) { where("date < ?", time) }
  scope :future_hangout, ->(time) { where("date > ?", time) }

  extend FriendlyId
  friendly_id :title, use: :slugged
  # geocoded_by :center_address
  # after_validation :geocode, if: :center_address?

end
