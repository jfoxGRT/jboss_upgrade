require 'java'
import 'java.lang.Integer'
begin
  import 'sami.web.SC'
rescue Exception => e
  p "WARNING: spring context is not loaded.  #{e}"
end

class SpringTestController < ApplicationController

	def sam_customer
		@name = params[:id].nil? ? '-' : SC.getBean("samCustomerService").retrieve(Integer.new(params[:id])).getName()
	end
	
end
