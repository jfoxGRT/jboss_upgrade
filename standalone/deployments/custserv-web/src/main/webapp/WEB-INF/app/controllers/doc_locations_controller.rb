class DocLocationsController < ApplicationController
  # GET /doc_locations
  # GET /doc_locations.xml
  
  # Layout: copied "new_layout_with_jeff_stuff into doc_items layout, then added YUI editing script
  layout 'doc_items'
  
  def index
    @doc_locations = DocLocation.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @doc_locations }
    end
  end

  # GET /doc_locations/1
  # GET /doc_locations/1.xml
  def show
    @doc_location = DocLocation.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @doc_location }
    end
  end

  # GET /doc_locations/new
  # GET /doc_locations/new.xml
  def new
    @doc_location = DocLocation.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @doc_location }
    end
  end

  # GET /doc_locations/1/edit
  def edit
    @doc_location = DocLocation.find(params[:id])
  end

  # POST /doc_locations
  # POST /doc_locations.xml
  def create
    @doc_location = DocLocation.new(params[:doc_location])

    respond_to do |format|
      if @doc_location.save
        flash[:notice] = 'DocLocation was successfully created.'
        format.html { redirect_to(@doc_location) }
        format.xml  { render :xml => @doc_location, :status => :created, :location => @doc_location }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @doc_location.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /doc_locations/1
  # PUT /doc_locations/1.xml
  def update
    @doc_location = DocLocation.find(params[:id])

    respond_to do |format|
      if @doc_location.update_attributes(params[:doc_location])
        flash[:notice] = 'DocLocation was successfully updated.'
        format.html { redirect_to(@doc_location) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @doc_location.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /doc_locations/1
  # DELETE /doc_locations/1.xml
  def destroy
    @doc_location = DocLocation.find(params[:id])
    @doc_location.destroy

    respond_to do |format|
      format.html { redirect_to(doc_locations_url) }
      format.xml  { head :ok }
    end
  end
end
