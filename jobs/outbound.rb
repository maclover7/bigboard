 SCHEDULER.every '30s', :first_in => 0 do |job|
   if Time.now.strftime("%H").between?("17", "19")
     status = TrainStatus.new(ENV["NJT_OUTBOUND_STATION"], ENV["NJT_OUTBOUND_NUMBER"]).get_status!(ENV["NJT_OUTBOUND_STATION"], ENV["NJT_OUTBOUND_NUMBER"])
     send_event('outbound', {status: "#{status}" })
   else
     status = "n/a"
     send_event('outbound', {status: "#{status}" })
   end
 end
