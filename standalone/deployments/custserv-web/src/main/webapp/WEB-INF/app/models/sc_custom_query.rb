class ScCustomQuery < ActiveRecord::Base
  
  set_table_name "sc_custom_queries"
  
  @@AGENT_SERVER_SEARCH = 'a'
  
  def self.AGENT_SERVER_SEARCH
    @@AGENT_SERVER_SEARCH
  end
  
end
# == Schema Information
#
# Table name: sc_custom_queries
#
#  id           :integer(10)     not null, primary key
#  name         :string(255)     not null
#  description  :text            not null
#  query_type   :string(1)       not null
#  where_clause :text            not null
#

