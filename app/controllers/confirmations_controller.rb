class ConfirmationsController < ApplicationController
  before_action :set_hangout
  before_action :set_confirmation, only: [:edit, :update, :destroy]

  def new
    if @hangout.confirmations.where('user_id = ?', current_user).count == 0
      @confirmation = Confirmation.new
      authorize @confirmation
    else
      redirect_to hangout_path(@hangout)
    end
  end

  def create
    @confirmation= Confirmation.new(confirmation_params)
    @confirmation.user = current_user
    @confirmation.hangout = @hangout

    authorize @confirmation

    if @confirmation.save
      if @hangout.user == current_user
        @hangout.latitude = @confirmation.latitude
        @hangout.longitude = @confirmation.longitude
        @hangout.adj_latitude = @confirmation.latitude
        @hangout.adj_longitude = @confirmation.longitude
        @hangout.save
        redirect_to share_hangout_path(@hangout)
      else
        #if not the user means that we need to calculate the search zone:
        search_zone
        redirect_to hangout_path(@hangout)
      end
    else
      render :new
    end
  end

  def edit
  end

  def update
  end

  def destroy
  end

private

  def search_zone
    #Building array of markets with leaving lat/lng of the confirmations
    confirmations = Confirmation.all.where('hangout_id = ?',@hangout.id)

    #Getting unadjusted search zone
    center = fetch_zone(confirmations)

    #Getting distance, duration to the center for each marker
    confirmations.each do |confirmation|
      get_direction(confirmation, center, @hangout.date)
    end
    #recalcute center adjusting lat, lng with duration
    adj_center = fetch_adjusted_zone(confirmations, center)

    #one more iteration for accuracy
    confirmations.each do |confirmation|
      get_direction(confirmation, adj_center, @hangout.date)
    end
    adj_center2 = fetch_adjusted_zone(confirmations, adj_center)

    @hangout.latitude = center[:lat]
    @hangout.longitude = center[:lng]
    @hangout.adj_latitude = adj_center2[:lat]
    @hangout.adj_longitude = adj_center2[:lng]
    @hangout.save
  end

  def fetch_zone(confirmations)
    nb = confirmations.count
    avg_lat = confirmations.reduce(0){ |sum, el| sum + el.latitude}.to_f / nb
    avg_ln = confirmations.reduce(0){ |sum, el| sum + el.longitude}.to_f / nb
    center = {lat: avg_lat, lng: avg_ln}

    delta_lat = (confirmations.max_by {|x| x.latitude}).latitude - (confirmations.min_by {|x| x.latitude}).latitude
    delta_lng = (confirmations.max_by {|x| x.longitude}).longitude - (confirmations.min_by {|x| x.longitude}).longitude
    raw_radius = (delta_lat + delta_lng) / 4
    magic_factor = 20000 #factor to size sensibility of the radius vs. distance between participants
    min_radius = 600
    @hangout.radius = [raw_radius * magic_factor, min_radius].max
    return center
  end

  def fetch_adjusted_zone(confirmations, center)
    div = confirmations.reduce(0){ |sum, el| sum + el.time_to_place}
    avg_lat = confirmations.reduce(0){ |sum, el| sum + el.latitude*el.time_to_place}.to_f / div
    avg_ln = confirmations.reduce(0){ |sum, el| sum + el.longitude*el.time_to_place}.to_f / div
    weighted_center = {lat: avg_lat, lng: avg_ln}
    adj_center = {lat: (weighted_center[:lat] + center[:lat]) / 2 , lng: (weighted_center[:lng] + center[:lng]) / 2 }
    return adj_center
  end

  def get_direction(confirmation, destination, departure_time)
    url = "https://maps.googleapis.com/maps/api/distancematrix/json?units=metric&origins=#{confirmation.latitude},#{confirmation.longitude}&destinations=#{destination[:lat]},#{destination[:lng]}&departure_time=#{departure_time.to_i}&mode=#{confirmation.transportation.downcase}&key=#{ENV['GOOGLE_API_SERVER_KEY']}"
    url.gsub!('"')
    direction = RestClient.get url
    direction_info = JSON.parse(direction)
    confirmation.distance_to_place = direction_info["rows"][0]["elements"][0]["distance"]["value"]
    if confirmation.transportation == 'DRIVING'
      confirmation.time_to_place = direction_info["rows"][0]["elements"][0]["duration_in_traffic"]["value"]
    else
      confirmation.time_to_place = direction_info["rows"][0]["elements"][0]["duration"]["value"]
    end
    authorize confirmation
    confirmation.save
    return confirmation
  end

  def set_confirmation
    @confirmation = Confirmation.find(params[:id])
  end

  def set_hangout
    @hangout = Hangout.find(params[:hangout_id])
    authorize @hangout
  end

  def confirmation_params
    # *Strong params*: You need to *whitelist* what can be updated by the user
    # Never trust user data!
    params.require(:confirmation).permit(:leaving_address, :transportation, :latitude, :longitude)
  end
end
