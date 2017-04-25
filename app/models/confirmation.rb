class Confirmation < ApplicationRecord
  belongs_to :user
  belongs_to :hangout
  belongs_to :place, optionnal: true

  geocoded_by :leaving_address
  after_validation :geocode, if: :leaving_address?

end
