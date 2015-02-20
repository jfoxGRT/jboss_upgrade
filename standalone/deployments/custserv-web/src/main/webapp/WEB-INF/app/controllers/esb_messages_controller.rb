class EsbMessagesController < ApplicationController
  
  #layout "new_layout_with_jeff_stuff"
  layout "default"
  
  def index
    @prototype_required = true
  end

  def new
    @tms_fake_in = TmsFakeIn.new
  end
  
  def create
    puts "params: #{params.to_yaml}"
    TmsFakeIn.create(params[:tms_fake_in])
    flash[:notice] = "Message successfully driven"
    redirect_to(:controller => :esb_message, :action => :index)
  end
  
  def search
    puts "params: #{params.to_yaml}"
    params[:esb_message_search].each_pair {|k,v| v.strip!}
    @esb_messages = EsbMessage.search(params[:esb_message_search])
    render (:template => "esb_messages/inbound_message_class", :layout => "cs_blank_layout")
  end
  
end
