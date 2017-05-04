class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :set_locale
  include Pundit

  after_action :verify_authorized, except: :index, unless: :skip_pundit?
  after_action :verify_policy_scoped, only: :index, unless: :skip_pundit?

    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  end

  # Check if there is a session hangout information
  def after_sign_in_path_for(resource)
    if session[:hangout].present?
      # save hangout
      @hangout = Hangout.new(session[:hangout]["hangout"])
      @hangout.user = current_user
      @hangout.status = "confirmations_on_going"

      if @hangout.force_location == true
        @hangout.adj_latitude = @hangout.latitude
        @hangout.adj_longitude = @hangout.longitude
        @hangout.radius = 600
      end

      if @hangout.save
        # clear session
      session[:hangout] = nil
        #redirect
      new_hangout_confirmation_path(@hangout)
      else
        new_hangout_path
      end
        # puts "***************************************************************"
        # new_hangout_path(@hangout)
      # end
    else
      super
    end
  end

  private

  def skip_pundit?
    devise_controller? || params[:controller] =~ /(^(rails_)?admin)|(^pages$)/
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(root_path)
  end

end
