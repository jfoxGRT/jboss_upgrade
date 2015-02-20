class ConvExportMasterBatch < ActiveRecord::Base
  set_table_name "conv_export_master_batch"
  has_many :conv_export_sub_batches


@@NUM_CONVO_SELECT_CLAUSE = "select count(ci.id) as the_count from conversation_instance ci, conv_export_sub_batch sb 
                                where ci.conv_export_sub_batch_id = sb.id and sb.conv_export_master_batch_id = ? "

  def self.find_open
  	find(:all, :conditions => ["closed = false"])
  end
 
  def self.find_most_recent_open
    find(:first, :conditions => ["closed = false"], :order => "created_at DESC")
  end

  # number of original conversations 
  def number_of_original_conversations
    return ConvExportMasterBatch.find_by_sql([ @@NUM_CONVO_SELECT_CLAUSE + " and retry_original_conversation_instance_id is null", self.id])[0].the_count
  end

  # number of retry conversations 
  def number_of_total_conversations
    return ConvExportMasterBatch.find_by_sql([ @@NUM_CONVO_SELECT_CLAUSE, self.id])[0].the_count
  end

  def sub_batches_for_ucn(ucn)
    return ConvExportSubBatch.find(:all,
                                   :select => "distinct sb.*",
                                   :joins => "sb inner join conversation_instance ci on ci.conv_export_sub_batch_id = sb.id
                                              inner join agent a on ci.agent_id = a.id
                                              inner join sam_server ss on ss.id = a.sam_server_id
                                              inner join sam_customer sc on sc.id = ss.sam_customer_id
                                              inner join org o on o.id = sc.root_org_id
                                              inner join customer c on c.id = o.customer_id",
                                   :conditions => ["c.ucn = ? and sb.conv_export_master_batch_id = ?", ucn, self.id], 
                                   :order => "sb.created_at ASC");
  end
  
  # return true if this master batch has no max dropped date at all, OR that date is in the past
  def is_dropped_dead?
    max_dropped_dead_date = get_max_dropped_dead_date
    (max_dropped_dead_date.nil? or max_dropped_dead_date.past?)
  end
  
  def get_max_dropped_dead_date
    max_dropped_dead_date = nil
    
    self.conv_export_sub_batches.each do |sub_batch|
      if sub_batch.drop_dead_date
        if(max_dropped_dead_date.nil? or sub_batch.drop_dead_date > max_dropped_dead_date)
          max_dropped_dead_date = sub_batch.drop_dead_date
        end
      end
    end
    
    max_dropped_dead_date
  end
  
end

# == Schema Information
#
# Table name: conv_export_master_batch
#
#  id                         :integer(10)     not null, primary key
#  export_date_range_end      :datetime        not null
#  export_date_range_1w_begin :datetime        not null
#  export_date_range_4w_begin :datetime        not null
#  created_at                 :datetime        not null
#  updated_at                 :datetime        not null
#  closed                     :boolean         default(FALSE), not null
#  initialized                :boolean         default(FALSE), not null
#

