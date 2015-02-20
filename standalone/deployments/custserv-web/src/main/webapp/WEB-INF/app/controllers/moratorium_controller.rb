class MoratoriumController < ApplicationController
  
  layout 'default_with_saplings_subtabs'
  
  def index 
  @moratorium = Moratorium.find(:all)
  end 
  
  def create_moratorium
       record = Moratorium.new
       if(params[:start_date])
         st = params[:start_time]       
         startdatetime = Time.parse(params[:start_date] + " " + st[:hour].to_s + ":" + st[:minute].to_s)
         record.start_datetime = startdatetime
       end
       if(params[:end_date])
         et = params[:end_time]       
         enddatetime = Time.parse(params[:end_date] + " " + et[:hour].to_s + ":" + et[:minute].to_s)
         record.end_datetime = enddatetime
       end
       if (params[:hosted])
        record.hosted_servers = true
       else
         record.hosted_servers = false
       end 
       if (params[:local]) 
        record.local_servers  = true
       else
         record.local_servers  = false 
       end 
       if (params[:sapcontent]) 
        record.sapling_content = true
       else
         record.sapling_content  = false 
       end 
       if (params[:samservercomp])
        record.sapling_component = true
       else
         record.sapling_component  = false
       end
       
       record.save
       
       flash[:notice] = "Moratorium saved."
       redirect_to(:action => :index)
  end   

  def delete_moratorium
      Moratorium.delete(Moratorium.first(:conditions => ["id = ?", params[:id]]))
      flash[:notice] = "Moratorium deleted."   
      redirect_to(:action => :index)    
  end

  def stop_moratorium
      record = Moratorium.first(:conditions => ["id = ?", params[:id]])
      record.end_datetime = Time.now
      record.save
      flash[:notice] = "Moratorium lifted."   
      redirect_to(:action => :index)    
  end
  
end