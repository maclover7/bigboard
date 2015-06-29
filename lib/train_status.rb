require 'rubygems'
require 'sinatra'
require 'open-uri'
require 'nokogiri'

class TrainStatus
  def initialize(station_code, train_number)
    @station_code = station_code
    @train_number = train_number
  end

  def get_status!(station_code, train_number)
    html = `curl http://dv.njtransit.com/mobile/tid-mobile.aspx?sid="#{station_code}"`

    doc = Nokogiri::HTML(html)
    nodes = doc.search('td[align="center"][valign="middle"]')

    status = ""

    nodes.each do |node|
      content = "#{node.next.next.next.next.content}|#{node.next.next.next.next.next.next.content}"
      train_id, train_status = content.split("|")
      if train_id == train_number
        status = train_status
        puts "#{status}"
      end
    end

    status

  end
end
