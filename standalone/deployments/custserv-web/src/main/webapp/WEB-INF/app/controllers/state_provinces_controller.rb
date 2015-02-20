class StateProvincesController < ApplicationController
  
  layout 'default'
  
  before_filter :load_state_province, :except => [:update_table]
  
  def index
    #@state_task_counts = Task.count_open_tasks_by_state_province
    #@state_sam_customer_counts = SamCustomer.count_by_us_state_province
    @activation_counts = SamCustomer.activation_counts_by_state_province
    @prototype_required = true
  end
  
  def show
    redirect_to(:controller => :tasks, :action => :category, :id => params[:id])
    return
  end
  
  protected
  
  def load_state_province
    @state_province = StateProvince.find(params[:state_id]) if (params[:state_id])
  end
  
end
