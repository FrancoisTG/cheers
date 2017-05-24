class Confirmation < ApplicationRecord
  belongs_to :user
  belongs_to :hangout
  belongs_to :place, optional: true

  TRANSPORTATION_MODE = ["DRIVING", "WALKING", "BICYCLING", "TRANSIT"]

  validates :latitude, presence: true
  validates :longitude, presence: true
  validates :transportation, presence: true, inclusion:{in: TRANSPORTATION_MODE}
  validates :user_id, presence: true, uniqueness: { scope: :hangout }
  validates :hangout_id, presence: true

  # geocoded_by :leaving_address
  # before_validation :geocode, if: :leaving_address?

end
