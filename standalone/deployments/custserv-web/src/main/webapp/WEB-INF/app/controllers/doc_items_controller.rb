class DocItemsController < ApplicationController
  # GET /doc_items
  # GET /doc_items.xml
  
  # Layout: copied "new_layout_with_jeff_stuff into doc_items layout, then added YUI editing script
  layout 'doc_items'
  
  #
  # INDEXES
  #
  
  def index
    redirect_to :controller => :doc_items, :action => :index_dashboard
  end
  

  def index_dashboard
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @doc_items }
    end
  end

  def index_faqs_cs
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @doc_items }
    end
  end

  def index_faqs_fe
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @doc_items }
    end
  end

  def index_faqs_e4e
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @doc_items }
    end
  end      

  def index_faqs_all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @doc_items }
    end
  end


  def index_manage
    @doc_items = DocItem.find(:all, :order => "display_order asc")  
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @doc_items }
    end
  end
  



  # Purpose: Show one doc item in details
  #  * GET /doc_items/1
  #  * GET /doc_items/1.xml
  #
  def show
    @doc_item = DocItem.find(params[:id])
    @doc_labels = DocLabel.find(:all, :order => "display_order asc")   
    @doc_locations = DocLocation.find(:all, :order => "display_location asc")           

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @doc_item }
    end
  end


  # Purpose: Create a new, empty record for user to enter data
  #   * Method Call Order: "new" --> "create"  
  #   * GET /doc_items/new
  #   * GET /doc_items/new.xml
  #
  def new
    @doc_item = DocItem.new
    @doc_item.user_selected_doc_label_ids = []        
    @doc_item.user_selected_doc_location_ids = []            
    
    @doc_item.ref_number = DocItem.maximum('ref_number') + 1
    @doc_labels = DocLabel.find(:all, :order => "display_order asc")
    @doc_locations = DocLocation.find(:all, :order => "display_location asc")    

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @doc_item }
    end
  end
  

  # Purpose: Profide user with an editable existing record
  #   * Method Call Order: "edit" --> "update"      
  #   * GET /doc_items/1/edit
  #
  def edit
    @doc_item = DocItem.find(params[:id])
    @doc_item.user_selected_doc_label_ids = [] 
    @doc_item.user_selected_doc_location_ids = []                         
    
    @doc_labels = DocLabel.find(:all, :order => "display_order asc")      
    @doc_labels.each {|dl| 
      @doc_item.user_selected_doc_label_ids << dl.id.to_s if @doc_item.doc_labels.with_code(dl.code)
    }      
    
    @doc_locations = DocLocation.find(:all, :order => "display_location asc")      
    @doc_locations.each {|dl| 
      @doc_item.user_selected_doc_location_ids << dl.id.to_s if @doc_item.doc_locations.with_code(dl.code)
    }          
  end


  # Purpose: Save a newly created record after user has populated fields
  #   * Method Call Order: "new" --> "create"    
  #   * POST /doc_items
  #   * POST /doc_items.xml
  #
  def create
    @doc_item = DocItem.new(params[:doc_item])
    @doc_item.user_selected_doc_label_ids = []   
    @doc_item.user_selected_doc_location_ids = [] 
    
    @doc_labels = DocLabel.find(:all, :order => "display_order asc")
    @doc_labels.each {|dl| 
      @doc_item.user_selected_doc_label_ids << dl.id.to_s if params[:doc_label].has_key?(dl.id.to_s) && params[:doc_label][dl.id.to_s] == '1'
    }          
    
    @doc_locations = DocLocation.find(:all, :order => "display_location asc")
    @doc_locations.each {|dl| 
      @doc_item.user_selected_doc_location_ids << dl.id.to_s if params[:doc_location].has_key?(dl.id.to_s) && params[:doc_location][dl.id.to_s] == '1'
    }              

    respond_to do |format|
      if @doc_item.save
        flash[:notice] = 'DocItem was successfully created.'
        format.html { redirect_to(@doc_item) }
        format.xml  { render :xml => @doc_item, :status => :created, :location => @doc_item }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @doc_item.errors, :status => :unprocessable_entity }
      end
    end
  end
  

  # Purpose: Update a record with user-entered updated data
  #   * Method Call Order: "edit" --> "update"        
  #   * PUT /doc_items/1
  #   * PUT /doc_items/1.xml
  #
  def update
    @doc_item = DocItem.find(params[:id])
    @doc_item.user_selected_doc_label_ids = []
    @doc_item.user_selected_doc_location_ids = []     
                     
    @doc_labels = DocLabel.find(:all, :order => "display_order asc")
    @doc_labels.each {|dl| 
      @doc_item.user_selected_doc_label_ids << dl.id.to_s if params[:doc_label].has_key?(dl.id.to_s) && params[:doc_label][dl.id.to_s] == '1'
    }              
    
    @doc_locations = DocLocation.find(:all, :order => "display_location asc")
    @doc_locations.each {|dl| 
      @doc_item.user_selected_doc_location_ids << dl.id.to_s if params[:doc_location].has_key?(dl.id.to_s) && params[:doc_location][dl.id.to_s] == '1'
    }                  

    respond_to do |format|
      if @doc_item.update_attributes(params[:doc_item])
        flash[:notice] = 'DocItem was successfully updated.'
        format.html { redirect_to(@doc_item) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @doc_item.errors, :status => :unprocessable_entity }
      end
    end
  end


  # Purpose: Delete 
  #   * DELETE /doc_items/1
  #   * DELETE /doc_items/1.xml
  #
  def destroy
    @doc_item = DocItem.find(params[:id])
    @doc_item.user_selected_doc_label_ids = [] 
    @doc_item.user_selected_doc_location_ids = []                        
    @doc_item.destroy

    respond_to do |format|
      format.html { redirect_to(doc_items_url) }
      format.xml  { head :ok }
    end
  end

  
end
