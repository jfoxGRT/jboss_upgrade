class ProcessMessageResponse < ActiveRecord::Base
  set_table_name "process_message_responses"
  belongs_to :process_message
  
  def self.count_by_token_code_phase(process_id, processor_code, phase, completed)
    completed_at_txt = (completed) ? "not null" : "null"
    find_by_sql(["select count(distinct pmr.id) as the_count from process_message_responses pmr
                  inner join process_messages pm on pmr.process_message_id = pm.id
                  where pm.process_id = ? and pmr.process_participator_code = ? and pmr.phase = ? and completed_at is #{completed_at_txt}",
                process_id, processor_code, phase])[0].the_count
  end
  
  def self.count_total_by_token_code_phase(process_id, processor_code, phase)
    find_by_sql(["select count(distinct pmr.id) as the_count from process_message_responses pmr
                  inner join process_messages pm on pmr.process_message_id = pm.id
                  where pm.process_id = ? and pmr.process_participator_code = ? and pmr.phase = ?",
                process_id, processor_code, phase])[0].the_count
  end
  
  def self.find_incomplete_by_group(process_id)
    find_by_sql(["select pmr.process_participator_code as processor_code, pmr.phase from process_message_responses pmr
        inner join process_messages pm on pmr.process_message_id = pm.id
        where pm.process_id = ? and pmr.completed_at is null
        group by pmr.process_participator_code, pmr.phase",process_id])
  end
  
end

# == Schema Information
#
# Table name: process_message_responses
#
#  id                        :integer(10)     not null, primary key
#  process_message_id        :integer(10)     not null
#  process_participator_code :string(8)       not null
#  created_at                :datetime        not null
#  completed_at              :datetime
#  phase                     :integer(10)     default(0), not null
#  checks                    :integer(10)     default(0), not null
#

