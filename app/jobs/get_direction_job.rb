class GetDirectionJob < ApplicationJob
  queue_as :default

  def perform(confirmation_id)
    confirmation = Hangout.find(confirmation_id)
    destination = {lat: confirmation.hangout.place.latitude, lng: confirmation.hangout.place.longitude}
    departure_time = confirmation.hangout.date

    url = "https://maps.googleapis.com/maps/api/distancematrix/json?units=metric&origins=#{confirmation.latitude},#{confirmation.longitude}&destinations=#{destination[:lat]},#{destination[:lng]}&departure_time=#{departure_time.to_i}&mode=#{confirmation.transportation.downcase}&key=#{ENV['GOOGLE_API_SERVER_KEY']}"
    url.gsub!('"')
    puts "****************url = #{url}"
    direction = RestClient.get url
     puts "****************direction = #{direction}"
    direction_info = JSON.parse(direction)
    confirmation.distance_to_place = direction_info["rows"][0]["elements"][0]["distance"]["value"]
    if confirmation.transportation == 'DRIVING'
      confirmation.time_to_place = direction_info["rows"][0]["elements"][0]["duration_in_traffic"]["value"]
    else
      confirmation.time_to_place = direction_info["rows"][0]["elements"][0]["duration"]["value"]
    end
    # authorize confirmation
    confirmation.save
  end
end
