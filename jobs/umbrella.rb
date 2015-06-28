require 'net/https'
require 'json'

# Forecast API Key from https://developer.forecast.io
forecast_api_key = ENV["FORECAST_API_KEY"]

# Latitude, Longitude for location
forecast_location_lat = ENV["FORECAST_LATITUDE"]
forecast_location_long = ENV["FORECAST_LONGITUDE"]

# Unit Format
# "us" - U.S. Imperial
# "si" - International System of Units
# "uk" - SI w. windSpeed in mph
forecast_units = "us"

SCHEDULER.every '5m', :first_in => 0 do |job|
  http = Net::HTTP.new("api.forecast.io", 443)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  response = http.request(Net::HTTP::Get.new("/forecast/#{forecast_api_key}/#{forecast_location_lat},#{forecast_location_long}?units=#{forecast_units}"))
  forecast = JSON.parse(response.body)

  probability_string = forecast["daily"]["data"].first['precipProbability'].to_s
  if probability_string > "0.20"
    needed = "Yes!"
  else
    needed = "No!"
  end

  probability_percent = (forecast["daily"]["data"].first['precipProbability'] * 100).to_s.delete('.0') + '%'

  send_event('umbrella', { needed: "#{needed}", prob: "#{probability_percent}"})
end
