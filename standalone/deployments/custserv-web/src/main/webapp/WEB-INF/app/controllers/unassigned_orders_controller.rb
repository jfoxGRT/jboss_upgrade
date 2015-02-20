class UnassignedOrdersController < TasksController
  
  layout "new_layout"
  
  def index
  end

  def assigned
    alert = Alert.find_by_code(Alert.UNASSIGNED_ENTITLEMENT_CODE)
    (redirect_to(:action => :index, :controller => :tasks) and return) if alert.nil?
    @task_packages, @number_of_tasks = Task.build_task_packages(nil, Alert.UNASSIGNED_ENTITLEMENT_CODE, Task.ASSIGNED)
    puts "@task_packages: #{@task_packages.to_yaml}"
    puts "@task_packages[0]: #{@task_packages[0].class}"
  end
  
  # show the first 50 tasks in order of descending priority
  def unassigned
    @alert = Alert.find_by_code(Alert.UNASSIGNED_ENTITLEMENT_CODE)
    (redirect_to(:action => :index, :controller => :tasks) and return) if @alert.nil?
    @task_packages, @number_of_tasks = Task.build_task_packages(nil, Alert.UNASSIGNED_ENTITLEMENT_CODE, Task.UNASSIGNED)
    logger.info "@number_of_tasks: #{@number_of_tasks}"
  end  
  
end
