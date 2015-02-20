class AgentPlugin < ActiveRecord::Base
  set_table_name "agent_plugin"
  belongs_to :agent
  
  # determine whether the AgentPlugin object has the latest version available in SAMC's sapling repository
  # based on the Saplings state (published vs unpublished). if the AgentPlugin version is later (greater) 
  # than the most recent sapling, as is common in test/dev environments, return true.
  def is_latest_globally_published?
    globally_published_saplings = Sapling.find_all_by_sapling_code(self.name, :conditions => "state = 'p'")
    
    # it's ok if an agent reports a plugin we don't have in the repo, especially for non-prod. this would be
    # the case in a clean SAMC environment with no saplings in the repository. return true, as we have no
    # newer version to offer.
    return true if globally_published_saplings.empty?
    
    latest_sapling_version_so_far = globally_published_saplings.first.version
    globally_published_saplings.each do |sapling|
      latest_sapling_version_so_far = sapling.version if SaplingsHelper.compare_maven_versions(sapling.version, latest_sapling_version_so_far) > 0
    end
    
    SaplingsHelper.compare_maven_versions(self.value, latest_sapling_version_so_far) >=0
  end
  
end

# == Schema Information
#
# Table name: agent_plugin
#
#  id       :integer(10)     not null, primary key
#  agent_id :integer(10)
#  value    :integer(10)
#  name     :string(255)
#

