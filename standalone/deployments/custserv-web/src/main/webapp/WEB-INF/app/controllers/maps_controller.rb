class MapsController < ApplicationController


  def show
    street = params[:address_line]
    response = Net::HTTP.get_response(URI.parse("http://maps.googleapis.com/maps/api/geocode/json?address=#{Rack::Utils.escape(street)}&sensor=false"))
    json = ActiveSupport::JSON.decode(response.body)
    @lat = json["results"][0]["geometry"]["location"]["lat"]
    @lng = json["results"][0]["geometry"]["location"]["lng"]
    logger.info @lat
    logger.info @lng
  end
  
end
