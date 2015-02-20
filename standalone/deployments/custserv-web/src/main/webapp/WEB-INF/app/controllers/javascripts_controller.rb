class JavascriptsController < ApplicationController
  
  def dynamic_sapling_codes
    puts "here is the format: #{params[:format]}"
    @sapling_codes = SaplingCode.find(:all)
    render(:content_type => "text/javascript")
  end
  
end
