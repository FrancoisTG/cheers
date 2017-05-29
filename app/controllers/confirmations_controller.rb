class ConfirmationsController < ApplicationController
  before_action :set_hangout
  before_action :set_confirmation, only: [:destroy]

  def new
    if @hangout.confirmations.where('user_id = ?', current_user).count == 0
      @confirmation = Confirmation.new
      authorize @confirmation
    else
      authorize @hangout
      redirect_to hangout_path(@hangout)
    end
  end

  def create
    @confirmation= Confirmation.new(confirmation_params)
    @confirmation.user = current_user
    @confirmation.hangout = @hangout
    authorize @confirmation

    if @confirmation.save
      if @hangout.confirmations.count == 1
        # if 1st confirmation, initiate hangout geo data
        if @hangout.optimize_location == false
          PlacesfoursquareJob.perform_later(@hangout.id)
          @hangout.status = "vote_on_going_transition" #will pass to "vote_on_going" upon completion of the 4square search
        else
          @hangout.adj_latitude = @confirmation.latitude
          @hangout.adj_longitude = @confirmation.longitude
          @hangout.latitude = @confirmation.latitude
          @hangout.longitude = @confirmation.longitude
          @hangout.radius = 800
        end
        @hangout.save
        if @hangout.user == current_user
          redirect_to share_hangout_path(@hangout)
        else
          ConfirmationMailer.guest_confirmed(@confirmation.id).deliver_later    ####   mail
          redirect_to hangout_path(@hangout)
        end
      else
        unless @hangout.optimize_location == false
          @hangout.adj_ready = false
          @hangout.save
          SearchZoneJob.perform_later(@hangout.id)
        end
        ConfirmationMailer.guest_confirmed(@confirmation.id).deliver_later    ####   mail
        redirect_to hangout_path(@hangout)
      end
    else
      render :new
    end
  end

  def destroy
    ConfirmationMailer.guest_cancelled(@confirmation.id).deliver_now    ####   mail
    @confirmation.destroy
    if @hangout.confirmations.count == 1
      sole_confirmation = @hangout.confirmations[0]
      @hangout.latitude = sole_confirmation.latitude
      @hangout.longitude = sole_confirmation.longitude
      @hangout.adj_latitude = sole_confirmation.latitude
      @hangout.adj_longitude = sole_confirmation.longitude
    else
      SearchZoneJob.perform_later(@hangout.id)
    end

    redirect_to profiles_show_path
    flash[:notice] = "Cancelamento feito!"
  end


  def search_zone
    #Building array of markers with leaving lat/lng of the confirmations
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

private
  def set_hangout
    @hangout = Hangout.friendly.find(params[:hangout_id])
  end

  def set_confirmation
    hangout_id = Hangout.friendly.find(params[:hangout_id]).id
    @confirmation = current_user.confirmations.where('hangout_id = ?',hangout_id)[0]
    authorize @confirmation
  end

  def confirmation_params
    # *Strong params*: You need to *whitelist* what can be updated by the user
    # Never trust user data!
    params.require(:confirmation).permit(:leaving_address, :transportation, :latitude, :longitude)
  end
end
