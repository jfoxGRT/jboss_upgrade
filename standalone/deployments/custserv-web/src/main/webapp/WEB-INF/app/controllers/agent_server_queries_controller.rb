class AgentServerQueriesController < ApplicationController
  
  layout "default"
  
  def index
    @products = Product.find(:all, :select => "p.*, pg.id as product_group_id, pg.description as product_group_description, pg.code as product_group_code, s.id as subcommunity_id", 
                          :joins => "p inner join product_group pg on p.product_group_id = pg.id left join subcommunity s on s.product_id = p.id" )
    @task_types = TaskType.find(:all, :order => "display_order")
  end
  
  def find_agents_servers
    puts "params: #{params.to_yaml}"
    @result_set = Agent.find_by_sql("select agent.id as agent_id, agent.updated_at, agent.next_poll_at, agent.last_ip, 
                                      sam_server.id as server_id, sam_server.name as server_name, sam_customer.name as sam_customer_name, sam_customer.id as sam_customer_id
                                      from agent left join sam_server on agent.sam_server_id = sam_server.id
                                      left join sam_customer on sam_server.sam_customer_id = sam_customer.id where " + params[:where_clause])
  end
  
  
  # AJAX handler for updating a product's visibility level based on a param containing the product id like:
  #   product_id_=product_id_103
  # this naming convention is to avoid confusion/collision with the reserved "id" param name in Rails, and to avoid
  # duplicate HTML entity IDs in the rendered view. 
  def update
    product_id = params[:product_id].gsub('product_id_', String.new) # ex. "product_id_103" => "103"
    product = Product.find(product_id)
    
    if product # the product should always be found
      product.visibility_level = params[:value]
      product.save!
    end
    
    render :text => params[:value]
  end
  
end
