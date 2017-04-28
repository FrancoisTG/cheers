class HangoutsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:create, :new, :index, :show]
  before_action :set_hangout, only: [:show, :edit, :update, :cancel_hg, :launch_vote, :close_vote]

  def new
    @hangout = Hangout.new
    authorize @hangout
  end

  def index
    @hangouts = policy_scope(Hangout)
  end

  def create
    if current_user.nil?
      session[:hangout] = params
      @hangout = Hangout.new
      @hangout.status = "confirmations_on_going"
      authorize @hangout
      #  redirect_to new_user_session_path
      redirect_to user_facebook_omniauth_authorize_path
     else
      @hangout = Hangout.new(hangout_params)
      @hangout.status = "confirmations_on_going"
      authorize @hangout
      @hangout.user = current_user
      if @hangout.save
        redirect_to new_hangout_confirmation_path(@hangout)
      else
        render :new
      end
     end
  end

  def show
    #Render router:
    if (@hangout.date + 6 * 60 * 60) < Time.now #add 6hours in order not to put the hg in past right away
      @render = 'past'
    else
      if @hangout.status == "confirmations_on_going"
        @render = 'confirmationfollowup'

        @confirmations = Confirmation.all.where('hangout_id = ?',@hangout.id)
        @confirmation_markers = []
        @confirmations.each do |confirmation|
          @confirmation_markers << {lat: confirmation.latitude, lng: confirmation.longitude}
        end

        nb = @confirmations.count
        avg_lat = @confirmations.reduce(0){ |sum, el| sum + el.latitude }.to_f / nb
        avg_ln = @confirmations.reduce(0){ |sum, el| sum + el.longitude }.to_f / nb
        @center = {lat: avg_lat, lng: avg_ln}

        delta_lat = (@confirmations.max_by {|x| x.latitude}).latitude - (@confirmations.min_by {|x| x.latitude}).latitude
        delta_lng = (@confirmations.max_by {|x| x.longitude}).longitude - (@confirmations.min_by {|x| x.longitude}).longitude

        raw_radius = (delta_lat + delta_lng) / 4

        magic_factor = 20000

        @radius = raw_radius * magic_factor

      elsif @hangout.status == "vote_on_going"
        @render = 'vote_option'
      elsif @hangout.status == "result"
        @render = 'result'
      elsif @hangout.status == "cancelled"
        @render = 'cancelled'
      end
    end
  end

  def launch_vote
    @hangout.status = "vote_on_going"
    @hangout.save
    redirect_to hangout_path(@hangout)
    #Send notifications
  end

  def edit
  end

  def update
    @hangout.update_attributes(hangout_params)
    redirect_to hangout_path(@hangout)
    #Send notifications
  end

  def cancel_hg
    @hangout.status = "cancelled"
    @hangout.save
    redirect_to hangout_path(@hangout)
  end

  def close_vote
    @hangout.status = "result"
    @hangout.place = Place.find(62)  # XXXXXXXXXX put calculation here to get the real vote ouput
    @hangout.save
    redirect_to hangout_path(@hangout)
  end

  private

  def hangout_params
    params.require(:hangout).permit(:title, :date, :category, :center_address, :status)
  end

  def set_hangout
    @hangout = Hangout.find(params[:id])
    authorize @hangout
  end

end
