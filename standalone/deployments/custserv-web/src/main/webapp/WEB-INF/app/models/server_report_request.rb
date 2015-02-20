class ServerReportRequest < ActiveRecord::Base
  set_table_name "server_report_request"
  belongs_to :conversation_instance
  belongs_to :sam_server

##### this is used for pagination. FYI this will be called for each pagination call.
  def self.load_four_hundred_records(id)
    ServerReportRequest.all(:conditions => ["sam_server_id = ?",id], :order => "created_at DESC", :limit => 300)
  end


  ### better search approach would be to create indexes
  def self.search_for_server_report(options)
    server_report_request = nil
    unless options[:id].empty?
       server_report_request = get_server_report_by_id(options[:id])
     return server_report_request
    end
    # searching by created at
    if is_report_type_present?(options[:report_type]) && is_request_type_present?(options[:request_type]) && is_updated_at_present?(options) && is_status_type_present?(options[:status]) && !is_created_at_present?(options)
      return server_report_request = get_server_report_by_created_at(options[:created_at])
    end
    # searching by updated at
    if is_report_type_present?(options[:report_type]) && is_request_type_present?(options[:request_type]) && is_created_at_present?(options) && is_status_type_present?(options[:status]) && !is_updated_at_present?(options)
      return server_report_request = get_server_report_by_updated_at(options[:created_at])
    end
    # searching by created at and updated at
     if is_report_type_present?(options[:report_type]) && is_request_type_present?(options[:request_type]) && is_status_type_present?(options[:status]) && !is_updated_at_present?(options) && !is_created_at_present?(options)
      return server_report_request = get_server_report_by_created_at_and_updated_at(options[:created_at], options[:updated_at])
    end
   # searching by report type
     if !is_report_type_present?(options[:report_type]) && is_request_type_present?(options[:request_type]) && is_updated_at_present?(options) && is_created_at_present?(options) && is_status_type_present?(options[:status])
      return server_report_request = get_server_report_by_report_type(options[:report_type])

    end
   # searching by request type
    if is_report_type_present?(options[:report_type]) && !is_request_type_present?(options[:request_type]) && is_updated_at_present?(options) && is_created_at_present?(options) && is_status_type_present?(options[:status])
      return server_report_request = get_server_report_by_request_type(options[:request_type])
    end
  # searching by status type
   if is_report_type_present?(options[:report_type]) && is_request_type_present?(options[:request_type]) && is_updated_at_present?(options) && is_created_at_present?(options) && !is_status_type_present?(options[:status])
      return server_report_request = get_server_report_by_status_type(options[:status])
    end
  # searching by report type and status type
    if !is_report_type_present?(options[:report_type]) && is_request_type_present?(options[:request_type]) && is_updated_at_present?(options) && is_created_at_present?(options) && !is_status_type_present?(options[:status])
      return server_report_request = get_server_report_request_by_report_and_status_type(options[:report_type],options[:status])
    end
  # searching by report type and request type
   if !is_report_type_present?(options[:report_type]) && !is_request_type_present?(options[:request_type]) && is_updated_at_present?(options) && is_created_at_present?(options) && is_status_type_present?(options[:status])
      return server_report_request = get_server_report_request_by_report_and_request_type(options[:report_type],options[:request_type])
    end
  # searching by status type and request type
   if is_report_type_present?(options[:report_type]) && !is_request_type_present?(options[:request_type]) && is_updated_at_present?(options) && is_created_at_present?(options) && !is_status_type_present?(options[:status])
      return server_report_request = get_server_report_request_by_status_and_request_type(options[:status],options[:request_type])
    end

  # searching default
    return server_report_request = ServerReportRequest.get_all_server_reports_ordered_by_creation_time

  end

  def self.get_server_report_request_by_status_and_request_type(status_type, request_type)
    stype = get_status_type_format(status_type)
    rtype = get_request_type_format(request_type)
    ServerReportRequest.all(:conditions => ["status = ? AND request_type = ? ",stype,rtype], :order => "created_at DESC", :limit => 1000)
  end

  def self.get_server_report_request_by_report_and_request_type(report_type,request_type)
     rtype = get_report_type_from_format(report_type)
     req_type = get_request_type_format(request_type)
     ServerReportRequest.all(:conditions => ["report_type = ? AND request_type = ? ",rtype,req_type], :order => "created_at DESC", :limit => 1000)

  end

  def self.get_server_report_request_by_report_and_status_type(report_type,status_type)
    rtype = get_report_type_from_format(report_type)
    stype = get_status_type_format(status_type)
    ServerReportRequest.all(:conditions => ["report_type = ? AND status = ? ",rtype,stype], :order => "created_at DESC", :limit => 1000)
  end

  def self.get_server_report_by_id(id)
    server_report_request = []
    begin
      server_report_request << ServerReportRequest.find(id)
    rescue Exception => e
      server_report_request << "Server Report Request Record with #{id} is not present"
    end
  end

  def self.get_server_report_by_created_at(created_date)
    ServerReportRequest.all(:conditions => ["created_at LIKE ?","%" +created_date +"%"], :order => "created_at DESC", :limit => 1000)
  end

  def self.get_server_report_by_updated_at(updated_date)
    ServerReportRequest.all(:conditions => ["updated_at LIKE ?","%" +updated_date +"%"], :order => "created_at DESC", :limit => 1000)
  end

  def self.get_server_report_by_created_at_and_updated_at(created_at, updated_at)
    create_like_query = '%' +created_at +'%'
    update_like_query = '%' +updated_at +'%'
    created_at_result = get_server_report_by_created_at(create_like_query)
    updated_at_result = get_server_report_by_updated_at(update_like_query)
    created_at_result + updated_at_result
  end

  def self.get_server_report_by_report_type(report_type)
    type = get_report_type_from_format(report_type)
    if type == "any"
      get_all_server_reports_ordered_by_creation_time
    else
      ServerReportRequest.all(:conditions =>["report_type = ?", type], :order => "created_at DESC", :limit => 1000)
    end
  end

  # default searching method for server report requests by descending creation time
  def self.get_all_server_reports_ordered_by_creation_time
    ServerReportRequest.all(:order => "created_at DESC", :limit => 1000)
  end

  def self.get_report_type_from_format(report_type)
    if report_type == "xml"
      return "x"
    elsif report_type == "pdf"
      return "p"
    else
      return "any"
    end
  end

  def self.get_server_report_by_request_type(request_type)
    type = get_request_type_format(request_type)
    if type == "any"
      get_all_server_reports_ordered_by_creation_time
    else
      puts " <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #{type}"
      ServerReportRequest.all(:conditions =>["request_type = ?", type], :order => "created_at DESC", :limit => 1000)
    end
  end

  def self.get_request_type_format(request_type)
    if request_type == "groupinator"
      return "g"
    elsif request_type == "report_scheduler"
      return "s"
    else
      return "any"
    end
  end

  def self.get_server_report_by_status_type(status_type)
    type = get_status_type_format(status_type)
    if type == "any"
      get_all_server_reports_ordered_by_creation_time
    else
      ServerReportRequest.all(:conditions => ["status = ?", type], :order => "created_at DESC", :limit => 1000)
    end
  end

  def self.get_status_type_format(status_type)
    if status_type == "complete"
      return "c"
    elsif status_type == "expired"
      return "e"
    elsif status_type == "failed"
      return "f"
    elsif status_type == "pending"
      return "p"
    else
      return "any"
    end
  end

  def self.is_report_type_present?(report_type)
    report_type == "any"
  end

  def self.is_request_type_present?(request_type)
    request_type == "any"
  end

  def self.is_status_type_present?(status)
    status == "any"
  end

  ## passing options since we can use empty?
  def self.is_created_at_present?(options)
    options[:created_at].empty?
  end

  def self.is_updated_at_present?(options)
    options[:updated_at].empty?
  end
end
# == Schema Information
#
# Table name: server_report_request
#
#  id                       :integer(10)     not null, primary key
#  created_at               :datetime        not null
#  updated_at               :datetime        not null
#  sam_server_id            :integer(10)     not null
#  user_id                  :string(255)     not null
#  cohort_type              :string(255)     not null
#  cohort_id                :string(255)     not null
#  date_range               :string(255)     not null
#  report_type_id           :string(255)     not null
#  grade_school_id          :string(255)
#  attribute_filters        :string(255)
#  group_filters            :string(255)
#  grade_filters            :string(255)
#  app_filters              :string(255)
#  additional_criteria      :string(255)
#  conversation_instance_id :integer(10)
#  report_type              :string(1)       default("x"), not null
#  request_type             :string(1)       default("g"), not null
#  embargo_until            :datetime
#  expiration_date          :datetime
#  name                     :string(255)
#  community                :integer(10)
#  date_range_start         :datetime
#  date_range_end           :datetime
#  receive_date             :datetime
#  status                   :string(1)       default("p"), not null
#

