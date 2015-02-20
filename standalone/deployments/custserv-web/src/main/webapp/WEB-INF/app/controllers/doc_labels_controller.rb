class DocLabelsController < ApplicationController
  # GET /doc_labels
  # GET /doc_labels.xml
  
  # Layout: copied "new_layout_with_jeff_stuff into doc_items layout, then added YUI editing script
  layout 'doc_items'
  
  def index
    @doc_labels = DocLabel.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @doc_labels }
    end
  end

  # GET /doc_labels/1
  # GET /doc_labels/1.xml
  def show
    @doc_label = DocLabel.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @doc_label }
    end
  end

  # GET /doc_labels/new
  # GET /doc_labels/new.xml
  def new
    @doc_label = DocLabel.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @doc_label }
    end
  end

  # GET /doc_labels/1/edit
  def edit
    @doc_label = DocLabel.find(params[:id])
  end

  # POST /doc_labels
  # POST /doc_labels.xml
  def create
    @doc_label = DocLabel.new(params[:doc_label])

    respond_to do |format|
      if @doc_label.save
        flash[:notice] = 'DocLabel was successfully created.'
        format.html { redirect_to(@doc_label) }
        format.xml  { render :xml => @doc_label, :status => :created, :location => @doc_label }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @doc_label.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /doc_labels/1
  # PUT /doc_labels/1.xml
  def update
    @doc_label = DocLabel.find(params[:id])

    respond_to do |format|
      if @doc_label.update_attributes(params[:doc_label])
        flash[:notice] = 'DocLabel was successfully updated.'
        format.html { redirect_to(@doc_label) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @doc_label.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /doc_labels/1
  # DELETE /doc_labels/1.xml
  def destroy
    @doc_label = DocLabel.find(params[:id])
    @doc_label.destroy

    respond_to do |format|
      format.html { redirect_to(doc_labels_url) }
      format.xml  { head :ok }
    end
  end
end
