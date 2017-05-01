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
      @hangout = Hangout.new
      authorize @hangout
      #  redirect_to new_user_session_path
      redirect_to user_facebook_omniauth_authorize_path
    else
      @hangout = Hangout.new(hangout_params)
      authorize @hangout
      @hangout.status = "confirmations_on_going"
      @hangout.user = current_user
      if @hangout.save
        session[:hangout] = nil
        if @hangout.force_location == true
          #hangout owner confirmation directly saved
          @confirmation = Confirmation.new(latitude: @hangout.latitude, longitude: @hangout.longitude, transportation: 'DRIVING')
          @confirmation.user = current_user
          @confirmation.hangout = @hangout
          authorize @confirmation
          @confirmation.save
          #launch vote
          initialize_places_api
          @hangout.status = "vote_on_going"
          @hangout.save
          HangoutMailer.creation_confirmation(@hangout).deliver_now    ####   mail
          redirect_to share_hangout_path(@hangout)
        else
          HangoutMailer.creation_confirmation(@hangout).deliver_now    ####   mail
          redirect_to new_hangout_confirmation_path(@hangout)
        end
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
  end

  def has_voted?
    confirmation.place.present?
  end
  helper_method :has_voted?

  def place_list
    @hangout.place_options
  end
  helper_method :place_list

  def voted_place
    confirmation.place
  end
  helper_method :voted_place

  def launch_vote
    # Call PlacesAPI to create place_options
    initialize_places_api
    @hangout.status = "vote_on_going"
    @hangout.save
    @hangout.confirmations do |confirmation|
      if confirmation.user != @hangout.user
        HangoutMailer.vote_starting(confirmation).deliver_now ####   mail
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
    HangoutMailer.update_confirmation(@hangout).deliver_now
    @hangout.confirmations do |confirmation|
      if confirmation.user != @hangout.user
        HangoutMailer.hangout_update(confirmation).deliver_now ####   mail
      end
    end
    redirect_to hangout_path(@hangout)
    #Send notifications
  end

  def cancel_hg
    @hangout.status = "cancelled"
    @hangout.save
    @hangout.confirmations do |confirmation|
      if confirmation.user != @hangout.user
        HangoutMailer.cancelled(confirmation).deliver_now ####   mail
      end
    end
    redirect_to hangout_path(@hangout)
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
    @hangout.confirmations do |confirmation|
      if confirmation.user != @hangout.user
        HangoutMailer.result(confirmation).deliver_now ####   mail
      end
    end
    redirect_to hangout_path(@hangout)
  end

  def share
  end

private

  def hangout_params
    params.require(:hangout).permit(:title, :date, :category, :center_address, :status, :force_location, :center_address, :latitude, :longitude)
  end

  def set_hangout
    @hangout = Hangout.find(params[:id])
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

      @center = {lat: @hangout.latitude, lng: @hangout.longitude}
      @adj_center = {lat: @hangout.adj_latitude, lng: @hangout.adj_longitude}
      @hangout.radius? ? @radius = @hangout.radius : @radius = 1  #necessary so that javascript can be compiled with radius nil
    elsif @hangout.status == "vote_on_going"
      @render = 'vote_option'
      @nb_conf = @hangout.confirmations.count
      @nb_vote = @hangout.confirmations.reduce(0) {|sum,conf| conf.place_id.nil? ? sum : sum  += 1}
    elsif @hangout.status == "result"
      @render = 'result'
      #confirmation
      #@confirmation = @hangout.confirmations.select {|confirmation| confirmation.user == current_user}
      @transport = confirmation.transportation
      @departure = {lat: @confirmation.latitude, lng: @confirmation.longitude}
      @direction = {lat: @hangout.latitude, lng: @hangout.longitude}
    elsif @hangout.status == "cancelled"
      @render = 'cancelled'
    end
  end

  def initialize_places_api
    fetch = PlacesApi.new(@hangout)
    venues = fetch.fetch_places
    fetch.find_places(venues)
  end

end
