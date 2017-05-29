class SearchZoneJob < ApplicationJob
  queue_as :default

  def perform(hangout_id)
    hg = Hangout.find(hangout_id)
    # sleep 10
    #Building array of markers with leaving lat/lng of the confirmations
    confirmations = Confirmation.all.where('hangout_id = ?',hg.id)
    #Getting unadjusted search zone and define radius
    nb = confirmations.count
    avg_lat = confirmations.reduce(0){ |sum, el| sum + el.latitude}.to_f / nb
    avg_ln = confirmations.reduce(0){ |sum, el| sum + el.longitude}.to_f / nb
    center = {lat: avg_lat, lng: avg_ln}

    delta_lat = (confirmations.max_by {|x| x.latitude}).latitude - (confirmations.min_by {|x| x.latitude}).latitude
    delta_lng = (confirmations.max_by {|x| x.longitude}).longitude - (confirmations.min_by {|x| x.longitude}).longitude
    raw_radius = (delta_lat + delta_lng) / 4
    magic_factor = 20000 #factor to size sensibility of the radius vs. distance between participants
    min_radius = 800
    hg.radius = [raw_radius * magic_factor, min_radius].max
puts "*************center: #{center[:lat]} / #{center[:lng]} ******************************"
    #Getting distance, duration to the center for each marker
    confirmations.each do |confirmation|
      get_direction(confirmation, center, hg.date)
    end
    #recalcute center adjusting lat, lng with duration
    adj_center = fetch_adjusted_zone(confirmations, center)
puts "*************adj_center: #{adj_center[:lat]} / #{adj_center[:lng]} ******************************"
    #one more iteration for accuracy
    confirmations.each do |confirmation|
      get_direction(confirmation, adj_center, hg.date)
    end
    adj_center2 = fetch_adjusted_zone(confirmations, adj_center)
puts "*************oufff******************************"
    hg.latitude = center[:lat]
    hg.longitude = center[:lng]
    hg.adj_latitude = adj_center2[:lat]
    hg.adj_longitude = adj_center2[:lng]
    hg.adj_ready = true
    hg.save
  end

private
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
 puts "****************url = #{url}"
    # url.gsub!('"')
    puts "****************url2 = #{url}"
    direction = RestClient.get url
     puts "****************direction = #{direction}"
    direction_info = JSON.parse(direction)
puts "*************puts gd2 ******************************"
    confirmation.distance_to_place = direction_info["rows"][0]["elements"][0]["distance"]["value"]
    if confirmation.transportation == 'DRIVING'
      confirmation.time_to_place = direction_info["rows"][0]["elements"][0]["duration_in_traffic"]["value"]
    else
      confirmation.time_to_place = direction_info["rows"][0]["elements"][0]["duration"]["value"]
    end
    # authorize confirmation
    confirmation.save
    return confirmation
  end
end
