class ConvExportSubBatch < ActiveRecord::Base
  set_table_name "conv_export_sub_batch"
  belongs_to :conv_export_master_batch
  has_many :conversation_instances


@@NUM_CONVO_SELECT_CLAUSE = "select count(ci.id) as the_count from conversation_instance ci
                                where ci.conv_export_sub_batch_id = ? "


  def self.find_open
  	find(:all, :select => "sb.*, mb.closed",
         :joins => "sb inner join conv_export_master_batch mb on sb.conv_export_master_batch_id = mb.id",
         :conditions => ["mb.closed = false"])
  end

  # number of original conversations 
  def number_of_original_conversations
    return ConvExportSubBatch.find_by_sql([ @@NUM_CONVO_SELECT_CLAUSE + " and retry_original_conversation_instance_id is null", self.id])[0].the_count
  end


end

# == Schema Information
#
# Table name: conv_export_sub_batch
#
#  id                          :integer(10)     not null, primary key
#  conv_export_master_batch_id :integer(10)     not null
#  drop_dead_date              :datetime        not null
#  conv_start_date             :datetime
#  conv_end_date               :datetime
#  created_at                  :datetime        not null
#  updated_at                  :datetime        not null
#  type_code                   :string(1)       not null
#  note                        :string(1024)
#

