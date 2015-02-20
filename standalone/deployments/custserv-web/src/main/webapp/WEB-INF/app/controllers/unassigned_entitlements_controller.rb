class UnassignedEntitlementsController < ApplicationController
  
  layout 'cs_layout'
  
  def index
    @entitlements = Entitlement.paginate(:page => params[:page], :select => "entitlement.*", 
                     :per_page => 15,
                     :joins => "inner join product on entitlement.product_id = product.id",
                     :conditions => "sam_customer_id is null", :order => "id desc")
  end
  
  def show
    @entitlement = Entitlement.find(params[:id])
  end
  
  #################
  # AJAX ROUTINES #
  #################

  def update_entitlement_table
    @entitlements = Entitlement.paginate(:page => params[:page],
           :select => "entitlement.*",
           :joins => "inner join product on entitlement.product_id = product.id",
           :conditions =>  "sam_customer_id is null", :order => entitlement_sort_by_param(params[:sort]), :per_page => 15)
    render(:partial => "entitlements_info", 
           :locals => {:entitlement_collection => @entitlements,
                       :status_indicator => params[:status_indicator],
                       :update_element => params[:update_element]})
  end
  
  private

  def entitlement_sort_by_param(sort_by_arg)
    case sort_by_arg
       when "entitlement_id" then "entitlement.id"
       when "order_date" then "entitlement.ordered"
       when "tms_entitlement_id" then "entitlement.tms_entitlementid"
       when "product_description" then "product.description"
       when "num_licenses" then "entitlement.license_count"
       when "order_number" then "entitlement.order_num"
       when "invoice_number" then "entitlement.invoice_num"
       when "created_at" then "entitlement.created_at"
       
       when "entitlement_id_reverse" then "entitlement.id desc"
       when "order_date_reverse" then "entitlement.ordered desc"
       when "tms_entitlement_id_reverse" then "entitlement.tms_entitlementid desc"
       when "product_description_reverse" then "product.description desc"
       when "num_licenses_reverse" then "entitlement.license_count desc"
       when "order_number_reverse" then "entitlement.order_num desc"
       when "invoice_number_reverse" then "entitlement.invoice_num desc"
       when "created_at_reverse" then "entitlement.created_at desc"
       else "entitlement.created_at desc"
       end
  end
  
end
