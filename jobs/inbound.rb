 SCHEDULER.every '30s', :first_in => 0 do |job|
   if Time.now.strftime("%H").between?("7", "8") 
     status = TrainStatus.new(ENV["NJT_INBOUND_STATION"], ENV["NJT_INBOUND_NUMBER"]).get_status!(ENV["NJT_INBOUND_STATION"], ENV["NJT_INBOUND_NUMBER"])
     send_event('inbound', {status: "#{status}" })
   else
     status = "n/a"
     send_event('inbound', {status: "#{status}" })
   end
end
