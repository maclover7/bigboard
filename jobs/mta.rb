require 'gtfs'
require 'time'
 
# Add the stations and lines you want to get updates on
# Example:
# target_stops = ['116 St - Columbia University', '8 St - NYU']
# target_lines = ['1','2','N']
# This will give you info on the trains on the 1, 2 and N at 116th St - Columbia University and 8 St - NYU
# You can get these names by downloading http://www.mta.info/developers/data/nyct/subway/google_transit.zip and
# checking for valid stop names under the file called 'stops'
 
target_stops = ENV["MTA_STOP"]
target_lines = ENV["MTA_LINE"]
 
# Change the refresh times if needed
# Updates list of trains arriving in the next 5 minutes (TIME) every 1 minute (UPDATE).
# Displays a particular train/stop combination data for 3 seconds (DISPLAY) before cycling to another
UPDATE = '1m'
TIME = 5 # Note that this is an integer, not a string (represents minutes)
DISPLAY = '3s'
 
request_flag = false
send_flag = false
source = nil
final_hash = Array.new
 
my_stop_ids = Array.new
stop_hash = Array.new
 
index = 0
 
stop_times = Array.new
 
# Retrieves GTFS data and builds primary data with lines of interest
SCHEDULER.every '24h', :first_in => 0 do |job|
  # Defaults to strict checking of required columns
  source = GTFS::Source.build('http://web.mta.info/developers/data/nyct/subway/google_transit.zip')
 
  # Get stop_ids of our stops of interest (these are listed in the array target_stops)
  source.stops.each do |stop|
    if target_stops.include? stop.name
 
      target_stop = Hash.new
 
      target_stop['name'] = stop.name
      target_stop['id'] = stop.id
 
      stop_hash.push(target_stop)
      my_stop_ids.push(stop.id)
    end
  end
 
  # Get stop_times at stops with our stop_ids
  stop_times = source.stop_times.select { |stop_time| my_stop_ids.include? stop_time.stop_id }
 
  # Set request_flag to true so that we can start calculating schedules 
  request_flag = true
end
 
 
# Calculates trains leaving in the next few minutes which stop at the target_stations
SCHEDULER.every UPDATE, :first_in => '5s' do |job|
  if request_flag == true
 
    send_flag = false
    final_hash = Array.new
 
    # Get stop_times from our stops with trains departing in the next 10 minutes
    stop_times.each do |stop_time|
 
      split_dept_time = stop_time.departure_time.split(':')
      dept_time = (3600*split_dept_time[0].to_i) + (60*split_dept_time[1].to_i) + (split_dept_time[2].to_i)
 
      time = Time.now.to_a
      now = 3600*time[2] + 60*time[1] + time[0]
 
      # Time difference in seconds
      diff = dept_time - now
 
      # If train leaves in next 5 minutes
      if 0 < diff && diff < TIME*60
 
        # Get line and direction based on trip_id
        # Then form objects containing final data to display
        selected_trip = source.trips.select { |trip| trip.id == stop_time.trip_id }
 
        # If line is one of our target lines, create data object
        if target_lines.include? selected_trip[0].route_id
 
          final_object = Hash.new
 
          stop = stop_hash.select { |hashed_stop| hashed_stop['id'] == stop_time.stop_id }
 
          final_object['name'] = stop[0]['name']
 
          # There are numbers 1 and 0 before the time strings
          # becausse we need to sort objects by time later.
          # This is a hack, and needs to be refined.
          mins = diff/60
          if mins == 0
            final_object['time'] = '0Leaving now'
          elsif mins == 1
            final_object['time'] = "1Arrives in #{mins} min"
          else
            final_object['time'] = "1Arrives in #{mins} mins"
          end
 
          final_object['line'] = selected_trip[0].route_id
          final_object['direction'] = selected_trip[0].headsign
 
          final_hash.push(final_object)
        end
      end
 
      send_flag = true
      final_hash.sort! { |obj1, obj2| obj1['time'] <=> obj2['time'] }
 
    end
  end
end
 
# Displays train/stop info, and cycles through the different data 
SCHEDULER.every DISPLAY, :first_in => '5s' do |job|
  line = ''
  name = 'Loading'
  direction = ''
  time = ''
 
  if send_flag == true
 
    if index >= final_hash.size
      index = 0
    end
 
    if final_hash.size > 0
      line = final_hash[index]['line']
      name = final_hash[index]['name']
      direction = final_hash[index]['direction']
 
      size = final_hash[index]['time'].size
      time = final_hash[index]['time'][1..size]
    end
    index = index + 1
  end
 
  send_event('mta', {line: line, name: name, direction: direction, time: time})
 
end
