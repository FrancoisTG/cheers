  class HangoutsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:create, :new, :show]

  before_action :set_hangout, only: [:show, :share, :edit, :update, :cancel_hg, :launch_vote, :submit_vote, :has_voted?,:close_vote]

  def new
    @hangout = Hangout.new(session.fetch(:hangout, {}).fetch("hangout", nil))
    authorize @hangout
  end

  def index
    @hangouts = policy_scope(Hangout)
  end

  def create
    if current_user.nil?
      session[:hangout] = params
      @hangout = Hangout.new(hangout_params)
      authorize @hangout

      if valid_param?(@hangout)
        #  redirect_to new_user_session_path
        redirect_to user_facebook_omniauth_authorize_path
      else
        render :new and return
      end

    else
      @hangout = Hangout.new(hangout_params)
      # @hangout.date = Time.parse(@hangout.date)
      authorize @hangout
      @hangout.status = "confirmations_on_going"
      @hangout.user = current_user

        # session[:hangout] = nil
      if @hangout.optimize_location == false
        @hangout.adj_latitude = @hangout.latitude
        @hangout.adj_longitude = @hangout.longitude
        @hangout.radius = 800
      end
      if @hangout.save
      HangoutMailer.creation_confirmation(@hangout.id).deliver_later    ####   mail
      redirect_to new_hangout_confirmation_path(@hangout)
      flash[:notice] = "Hangout criado com sucesso!"
      else
        render :new
      end
    end
  end

  def show
    #Render router:
    hg_confirmations = @hangout.confirmations.map {|x| x.user}
    if (@hangout.date + 6 * 60 * 60) > Time.now #add 6hours in order not to put the hg in past right away
      if current_user.nil?
        @render = 'invitation'
      else
        if hg_confirmations.include?(current_user)  #checking if current user has already a confirmation for this HG
          hangoutshow_by_status
        else
          @render = 'invitation'
        end
      end
    else
      @render = 'past'
    end
  end

  def submit_vote
    place = Place.find(params[:place_id])
    confirmation.place = place
    authorize @hangout
    @confirmation.save
    redirect_to hangout_path(@hangout)
    flash[:notice] = "Voto realizado com sucesso!"
  end

  def has_voted?
    confirmation.place.present?
  end
  helper_method :has_voted?

  def voted_place
    confirmation.place
  end
  helper_method :voted_place

  def launch_vote
    PlacesfoursquareJob.perform_later(@hangout.id)

    @hangout.status = "vote_on_going_transition" #will pass to "vote_on_going" upon completion of the 4square search
    @hangout.save
    @hangout.confirmations.each do |confirmation|
      if confirmation.user != @hangout.user
        HangoutMailer.vote_starting(confirmation.id).deliver_later ####   mail
      end
    end
    redirect_to hangout_path(@hangout)
    #Send notifications
  end

  def edit
  end

  def update
    @hangout.update_attributes(hangout_params)
    #launch_vote_hangout_path(@hangout)
    HangoutMailer.update_confirmation(@hangout.id).deliver_later
    @hangout.confirmations.each do |confirmation|
      if confirmation.user != @hangout.user
        HangoutMailer.hangout_update(confirmation.id).deliver_later ####   mail
      end
    end
    redirect_to hangout_path(@hangout)
    flash[:notice] = "Hangout editado!"
    #Send notifications
  end

  def cancel_hg
    @hangout.status = "cancelled"
    @hangout.save
    @hangout.confirmations.each do |confirmation|
      if confirmation.user != @hangout.user
        HangoutMailer.cancelled(confirmation.id).deliver_later ####   mail
      end
    end
    redirect_to profiles_show_path
    flash[:notice] = "Hangout cancelado!"
  end

  def close_vote
    votes = []
    @hangout.confirmations.each do |conf|
      if conf.place
       votes << conf.place
      end
    end
    counts = Hash.new 0
    votes.each do |place|
      counts[place] += 1
    end
    higher_vote = counts.max_by{|k,v| v}[1] #higher vote number
      if counts.select { |key, value| value == higher_vote }.size > 1 #check whether more than one places as the highest vote number
        places = counts.select { |key, value| value == higher_vote }.keys # array with winners
        places_rating = Hash.new 0
          places.each do |place|
          places_rating[place] = place.rating
        end
        higher_rating = places_rating.max_by{|k,v| v}[1]
        if places_rating.select { |key, value| value == higher_rating }.size > 1 #higher vote number
          choice = places_rating.select { |key, value| value == higher_rating }.keys
          winner = choice.sample
        else
          winner = places_rating.max_by{|k,v| v}[0]
        end
      else
        winner = counts.max_by{|k,v| v}[0]
      end
    @hangout.place = winner
    @hangout.status = "result"
    @hangout.save!

    # winner_coord = {lat: winner.latitude, lng: winner.longitude}

    #update travel time and distance
    owner_confirmation = @hangout.confirmations.where('user_id = ?', @hangout.user.id)
    GetDirectionJob.perform_now(owner_confirmation[0].id)
    @hangout.confirmations.each do |confirmation|
      if confirmation.user != @hangout.user
        HangoutMailer.result(confirmation.id).deliver_later ####   mail
        GetDirectionJob.perform_later(confirmation.id)
      # get_direction(confirmation, winner_coord, @hangout.date)
      end
    end
    redirect_to hangout_path(@hangout)
  end

  def share
  end

private

  def hangout_params
    params.require(:hangout).permit(:title, :date, :category, :center_address, :status, :optimize_location, :center_address, :latitude, :longitude)
  end

  def set_hangout
    @hangout = Hangout.friendly.find(params[:id])
    authorize @hangout
  end

  def confirmation
    @confirmation ||= Confirmation.find_by(user: @current_user, hangout: @hangout)
  end

  def hangoutshow_by_status
    if @hangout.status == "confirmations_on_going"
      @render = 'confirmationfollowup'
      @confirmations = Confirmation.all.where('hangout_id = ?',@hangout.id)
      @confirmation_markers = []
      @confirmations.each do |confirmation|
        @confirmation_markers << {lat: confirmation.latitude, lng: confirmation.longitude}
      end

      @confirmation = current_user.confirmations.where('hangout_id = ?',@hangout.id)

      @center = {lat: @hangout.latitude, lng: @hangout.longitude}
      @adj_center = {lat: @hangout.adj_latitude, lng: @hangout.adj_longitude}
      @hangout.radius? ? @radius = @hangout.radius : @radius = 1  #necessary so that javascript can be compiled with radius nil

      if @hangout.adj_ready == true
        respond_to do |format|
          format.html # show.html.erb
          format.json { render json: @adj_center } # quel status pour déclancher?
          format.js # show.js.erb
        end
      end

    elsif @hangout.status == "vote_on_going" || @hangout.status == "vote_on_going_transition"
      @render = 'vote_option'
      @nb_conf = @hangout.confirmations.count
      @nb_vote = @hangout.confirmations.reduce(0) {|sum,conf| conf.place_id.nil? ? sum : sum  += 1}

      unless @hangout.place_options.first.nil?
        places = @hangout.place_options
        respond_to do |format|
          format.html # show.html.erb
          format.json { render json: places }
          format.js # show.js.erb
        end
      end

    elsif @hangout.status == "result"
      @render = 'result'
      #confirmation
      @confirmations = Confirmation.all.where('hangout_id = ?',@hangout.id)

      @transport = confirmation.transportation
      @confirmation.time_to_place.nil? ? @leaving_time = 0 : @leaving_time = (@hangout.date - @confirmation.time_to_place)

      @departure = {lat: @confirmation.latitude, lng: @confirmation.longitude, address: @confirmation.leaving_address}
      @direction = {lat: @hangout.place.latitude, lng: @hangout.place.longitude, address: @hangout.place.address}
      @google_url = "//www.google.com/maps/dir/#{@departure[:lat]},#{@departure[:lng]}/#{@direction[:lat]},#{@direction[:lng]}"
#      @uber_url = "//m.uber.com/ul/?action=setPickup&client_id=BPnTmYM3BWbe7xQhQ7ATVyCcjWAx6HfJ&pickup=my_location&dropoff[latitude]=#{@direction[:lat]}&dropoff[longitude]=#{@direction[:lng]}', target: 'blank'%>"
      @uber_url = "//m.uber.com/ul/?action=setPickup&client_id=BPnTmYM3BWbe7xQhQ7ATVyCcjWAx6HfJ&pickup=my_location&dropoff[latitude]=#{@direction[:lat]}&dropoff[longitude]=#{@direction[:lng]}&dropoff[formatted_address]=#{@direction[:address]}"
      @taxi_url = "taxis99://call?"
#      @taxi_url = "taxis99://call?endLat=#{@direction[:lat]}&endLng=#{@direction[:lng]}&endName=#{@direction[:address]}"
    elsif @hangout.status == "cancelled"
      @render = 'cancelled'
    end
  end

  def valid_param?(hangout)
    unless hangout.title.nil?
      if (hangout.title.length < 61) && (hangout.title.length> 0)
        a = true
      end
    end
    unless hangout.date.nil?
      if hangout.date > Time.now
        b = true
      end
    end
    unless hangout.category.nil?
      if hangout.category.length > 0
        c = true
      end
    end
    return a && b && c
  end
end
