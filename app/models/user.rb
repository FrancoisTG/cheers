class User < ApplicationRecord
  # has_many hangouts, dependent: :destroy
  # has_many confirmations, dependent: :destroy

  # after_create :send_welcome_email
  before_save :set_avatar_placeholder

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:facebook]

  validates :first_name, presence: true
  validates :last_name, presence: true

  # mount_uploader :photo, PhotoUploader

  def self.find_for_facebook_oauth(auth)
    user_params = auth.slice(:provider, :uid)
    user_params.merge! auth.info.slice(:email, :first_name, :last_name)
    user_params[:facebook_picture_url] = auth.info.image
    user_params[:token] = auth.credentials.token
    user_params[:token_expiry] = Time.at(auth.credentials.expires_at)
    user_params = user_params.to_h
    user = User.where(provider: auth.provider, uid: auth.uid).first
    user ||= User.where(email: auth.info.email).first # User did a regular sign up in the past.
    if user
      user.update(user_params)
    else
      user = User.new(user_params)
      user.password = Devise.friendly_token[0,20] # Fake password for validation
      user.save
    end
    return user
  end



private

  def set_avatar_placeholder
    self.avatar_url = "avatar-placeholder.png" unless self.avatar_url.present?
  end

#   def send_welcome_email
#     UserMailer.welcome(self).deliver_now
#   end

end
