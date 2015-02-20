class TaskOrgsController < ApplicationController
	
	#################
	# AJAX ROUTINES #
	#################
	
	def destroy
		puts "params: #{params.to_yaml}"
		TaskOrg.delete_all(["task_id = ? and org_id = ?", params[:task_id], params[:org_id]])
		render(:text => "")
	end
	
end
