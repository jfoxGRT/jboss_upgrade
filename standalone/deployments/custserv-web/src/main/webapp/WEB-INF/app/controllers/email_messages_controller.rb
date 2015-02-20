require 'fastercsv'

class EmailMessagesController < ApplicationController  

  layout 'cs_layout'

  def show
    @email = EmailMessage.find(params[:id])
	  render(:layout => "cs_blank_layout")
  end
  
  
  def search
  	#put whole array from email search form into session
    #when a request for csv export comes in, :email_message will not be included in the request
    if (params[:email_message])
      session[:email_message] = params[:email_message]
    end
	
  	payload = params[:email_message]
          
  	@email_messages = find_email_messages(payload, FINDER_LIMIT)
  				
  	@num_rows_reported = @email_messages.length		
	
    if(request.xhr?) #if an ajax request...
    	render(:partial => "search") #render partial
    else
    	render(:layout => "cs_blank_layout") #otherwise, render other default layout
    end

  end

  def find_email_messages(payload, limit)
    response = CustServServicesHandler.new.dynamic_new_request_email_finder(request.env['HTTP_HOST'],
                                                                           payload,
                                                                           CustServServicesHandler::ROUTES['email_finder_web_services'] + "#{limit.to_s}") 
    
	parsed_json = ActiveSupport::JSON.decode(response.body)
	@email_messages = []
	@errors = []
	errorsMap = parsed_json["errors"]
	if(errorsMap)
	  puts errorsMap
	  parsed_json["errors"].each do |err|
	    err_row = ActiveSupport::JSON.decode(ActiveSupport::JSON.encode(err))
	    err_row.each {|k,v|
		  @errors << v
	    }
	  end
	else		
		parsed_json["emails"].each do |e|
			em = EmailMessage.new
			e.each {|k,v|
				em[k.to_sym] = v
			}
			
			@email_messages << em
		end
	end
	@ret_messages = @email_messages
  end


  # query for a sorted result set of SAM Servers via ActiveRecord.
  # this method is somewhat deprecated; only used for large result sets where Finder's WebAPI limit is problematic.
  def get_email_messages(sortby = 'email_id', limit = -1)
    #limit defines the max number of records to return from the query. A negative indicates no limit
  	case (sortby) 
      when "email_id_desc" then orders_clause = "id desc"
      when "email_type" then orders_clause = "description"
  	  when "email_type_desc" then orders_clause = "description desc"
  	  when "user_id" then orders_clause = "user_id"
  	  when "user_id_desc" then orders_clause = "user_id desc"
  	  when "to_address" then orders_clause = "recipient_address"
  	  when "to_address_desc" then orders_clause = "recipient_address desc"
  	  when "gen_date" then orders_clause = "generated_date"
  	  when "gen_date_desc" then orders_clause = "generated_date desc"
  	  when "sent_date" then orders_clause = "sent_date"
  	  when "sent_date_desc" then orders_clause = "sent_date desc"
      when "cust_id" then orders_clause = "cust_id"
      when "cust_id_desc" then orders_clause = "cust_id desc"
      when "cust_name" then orders_clause = "cust_name"
      when "cust_name_desc" then orders_clause = "cust_name desc"
      else orders_clause = "id"
    end
	  
    #taking out DISTINCT here since we're only doing 1:1 joins, but put it back if 1:many joins are added
    select_clause = "em.*, et.description, sc.id as cust_id, sc.name as cust_name"
    joins_clause = "em inner join email_type et on em.email_type_id = et.id left join users u on em.user_id = u.id left join sam_customer sc on u.sam_customer_id = sc.id"
    conditions_clause = "true " #need an initial string we can append to for WHERE AND AND AND...
    conditions_clause_fillins = []
  
    #put whole array from email search form into session
    #when a resubmit comes in from the user sorting the list, :email_message will not be included in the request
    if (params[:email_message])
      session[:email_message] = params[:email_message]
    end
  
    #use session from now on since only the initial request (not subsequent requests for sorting) will have the :email_message array in the request
  	if (session[:email_message][:email_type] && !session[:email_message][:email_type].empty?)
        conditions_clause += "and et.id = ? "
        conditions_clause_fillins << session[:email_message][:email_type]
    end
    if (session[:email_message][:user_id] && !session[:email_message][:user_id].strip.empty?)
    		conditions_clause += "and em.user_id = ? "
    		conditions_clause_fillins << session[:email_message][:user_id]
  	end
    if (session[:email_message][:auth_user_id] && !session[:email_message][:auth_user_id].strip.empty?)
  		  conditions_clause += "and em.auth_user_id = ? "
  	   	conditions_clause_fillins << session[:email_message][:auth_user_id]
  	end
    if (session[:email_message][:cust_id] && !session[:email_message][:cust_id].strip.empty?)
  		  conditions_clause += "and sc.id = ? "
  	   	conditions_clause_fillins << session[:email_message][:cust_id]
  	end
  	if (session[:email_message][:to_address] && !session[:email_message][:to_address].strip.empty?)
    		conditions_clause += "and em.recipient_address like ? "
        #swiching from '%address%' to 'address%', allows use of index, query is very slow otherwise, hope no one complains
    		conditions_clause_fillins << (session[:email_message][:to_address] + "%")
  	end
    if ((session[:email_message][:generated_date_start] && !session[:email_message][:generated_date_start].strip.empty?) || 
  	      (session[:email_message][:generated_date_end] && !session[:email_message][:generated_date_end].strip.empty?))
  	  if ((session[:email_message][:generated_date_start] && !session[:email_message][:generated_date_start].strip.empty?) && 
        	    (session[:email_message][:generated_date_end] && !session[:email_message][:generated_date_end].strip.empty?))
            conditions_clause += "and em.generated_date between '#{session[:email_message][:generated_date_start]} 00:00:00' and '#{session[:email_message][:generated_date_end]} 23:59:59'"
      elsif (session[:email_message][:generated_date_start] && !session[:email_message][:generated_date_start].strip.empty?)
          conditions_clause += "and em.generated_date >= '#{session[:email_message][:generated_date_start]}'"
      else
          conditions_clause += "and em.generated_date <= '#{session[:email_message][:generated_date_end]}'"
      end
    end
    if ((session[:email_message][:sent_date_start] && !session[:email_message][:sent_date_start].strip.empty?) || 
  	      (session[:email_message][:sent_date_end] && !session[:email_message][:sent_date_end].strip.empty?))
  	  if ((session[:email_message][:sent_date_start] && !session[:email_message][:sent_date_start].strip.empty?) && 
        	    (session[:email_message][:sent_date_end] && !session[:email_message][:sent_date_end].strip.empty?))
            conditions_clause += "and em.sent_date between '#{session[:email_message][:sent_date_start]} 00:00:00' and '#{session[:email_message][:sent_date_end]} 23:59:59'"
      elsif (session[:email_message][:sent_date_start] && !session[:email_message][:sent_date_start].strip.empty?)
          conditions_clause += "and em.sent_date >= '#{session[:email_message][:sent_date_start]}'"
      else
          conditions_clause += "and em.sent_date <= '#{session[:email_message][:sent_date_end]}'"
      end
    end
    if ((session[:email_message][:ignored_date_start] && !session[:email_message][:ignored_date_start].strip.empty?) || 
  	      (session[:email_message][:ignored_date_end] && !session[:email_message][:ignored_date_end].strip.empty?))
  	  if ((session[:email_message][:ignored_date_start] && !session[:email_message][:ignored_date_start].strip.empty?) && 
        	    (session[:email_message][:ignored_date_end] && !session[:email_message][:ignored_date_end].strip.empty?))
            conditions_clause += "and em.ignored_date between '#{session[:email_message][:ignored_date_start]} 00:00:00' and '#{session[:email_message][:ignored_date_end]} 23:59:59'"
      elsif (session[:email_message][:ignored_date_start] && !session[:email_message][:ignored_date_start].strip.empty?)
          conditions_clause += "and em.ignored_date >= '#{session[:email_message][:ignored_date_start]}'"
      else
          conditions_clause += "and em.ignored_date <= '#{session[:email_message][:ignored_date_end]}'"
      end
    end
    
    @limit = limit
    if (limit < 0)
      @email_messages = EmailMessage.find(:all, :select => select_clause, :joins => joins_clause, :conditions => [conditions_clause, conditions_clause_fillins].flatten, :order => orders_clause)
    else
      @email_messages = EmailMessage.find(:all, :select => select_clause, :joins => joins_clause, :conditions => [conditions_clause, conditions_clause_fillins].flatten, :order => orders_clause, :limit => limit)
    end
  end


  def export_email_search_to_csv
    logger.info "EXPORTING CSV"
    
    email_search_results = get_email_messages # server-side CSV always uses default sort, not necessarily current sort in finder display 
    csv_string = FasterCSV.generate do |csv_row|
      # header row
      csv_row << ["ID", "Email Type", "User ID", "Recipient Address", "Generated", "Sent", "Customer ID", "Customer Name"]
      email_search_results.each do |email_message|
        #populating each data row with database fields
        csv_row << [email_message.id, email_message.description, email_message.user_id, email_message.recipient_address, email_message.generated_date.strftime(DATE_FORM), (email_message.sent_date ? email_message.sent_date.strftime(DATE_FORM) : nil), email_message.cust_id, (email_message.cust_name ? email_message.cust_name.strip : nil)]
      end
    end
    
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => EMAIL_FINDER_RESULTS_FILENAME )
  end 
  
end
