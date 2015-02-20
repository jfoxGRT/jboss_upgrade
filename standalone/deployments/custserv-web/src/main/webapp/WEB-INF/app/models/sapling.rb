class Sapling < ActiveRecord::Base
  
  include SaplingsHelper
  
  set_table_name "sapling"
  
  attr_accessor :binary_data, :update_sapling_file, :creating_file
  
  COMPONENT_TYPE_CODE = 'SAM_SERVER_COMPONENT'
  CONTENT_TYPE_CODE = 'CONTENT'
  PLUGIN_TYPE_CODE = 'PLUGIN'
  MICROLOADER_TYPE_CODE = 'MICROLOADER'
  
  
  def sapling_file=(input_data)
    self.creating_file = true
    return if (input_data.nil? || (input_data.length == 0))
    self.binary_data = input_data.read
  end
  
  def update_file=(input_data)
    return if (input_data.nil?)
    self.update_sapling_file = input_data
  end
  
  def isPlugin
    return (self.sapling_type == 'PLUGIN' || self.sapling_type == 'MICROLOADER' || self.sapling_type == 'CLIENT') 
  end   
  
  
  # get the latest (highest versioned) sapling for the product matching the given agent_component. exclude versions that
  # don't pertain to the same GM release (alternatively stated: aren't in the upgrade path). include versions that do
  # pertain to the same GM release but are lower than the agent_component version.
  #   ex: agent_component => { :name => "slms", value: => "3208025"}
  #       published saplings in repo: [
  #                                     { :sapling_code => "slms", :version => "3208023" },   # Balthazar
  #                                     { :sapling_code => "slms", :version => "8869" },      # JerBul
  #                                     { :sapling_code => "slms", :version => "2.2.5.6.1" }, # Duke
  #                                     { :sapling_code => "slms", :version => "3208028" }    # Balthazar
  #                                   ]
  #       return: the sapling with version "3208028". if this one didn't exist however, we'd return the sapling with
  #               version "3208023". 
  def self.get_latest_published_by_agent_component(agent_component)
    return nil unless agent_component
    
    all_published_by_code = self.find_all_by_sapling_code(agent_component.name, :conditions => "state = 'p'")
    return nil if all_published_by_code.empty?
    
    latest_by_code = nil
    all_published_by_code.each do |sapling|
      next unless (sapling[:sapling_type] == CONTENT_TYPE_CODE or sapling.same_major_release?(agent_component.value))
      if latest_by_code
        latest_by_code = sapling if SaplingsHelper.compare_release_versions(sapling.version, latest_by_code.version) > 0
      else
        latest_by_code = sapling # seed latest_by_code if it's null, now that we know this sapling is in the same major release
      end
    end
    
    return latest_by_code
  end
  
  
  # return true iff this sapling is of the same major SAM release as the given version. this method is applicable
  # to component saplings; return false if this is not a component sapling.
  def same_major_release?(version)
    return false unless self[:sapling_type] == COMPONENT_TYPE_CODE
    
    my_major_release = SaplingsHelper.get_major_release(self.version)
    comparison_major_release = SaplingsHelper.get_major_release(version)
    
    # if one or both are nil, return false. this must be a erroneous or very old/new version that SaplingsHelper 
    # doesn't know about.
    return false if (my_major_release.nil? or comparison_major_release.nil?)
    (my_major_release == comparison_major_release)
  end
  
  #validates_presenc_of :sapling_code, :version, :os_family, :os_series, :cpu_type, :cpu_bits
  validates_inclusion_of :scheduled, :in => [true, false]
  #validates_numericality_of :version, :only_integer => true
  
  SAPLING_CODES = [
    ["auth", "auth"],
    ["core",        "core"],
	["cn", "cn"],
    ["diagnostic", "diagnostic"],
	["depends", "depends"],
    ["fad", "fad"],
    ["fm", "fm"],
    ["fmng", "fmng"],
    ["jre", "jre"],
    ["licensing",   "licensing"],
    ["microloader", "microloader"],
    ["productupdate", "productupdate"],
    ["r180", "r180"],
	["r180ng", "r180ng"],
    ["ra", "ra"],
    ["rt", "rt"],
	["rtng", "rtng"],
    ["s44", "s44"],
    ["s44ng", "s44ng"],
    ["slms", "slms"],
    ["smi", "smi"],
    ["spi", "spi"],
    ["src", "src"],
	["srcquiz01", "srcquiz01"],
	["srcquiz02", "srcquiz02"],
	["srcquiz03", "srcquiz03"],
	["srcquiz04", "srcquiz04"],
	["srcquiz05", "srcquiz05"],
    ["sri", "sri"],
    ["subcmdr", "subcmdr"],
    ["subcommander", "subcommander"]
  ]
  
  SAPLING_TYPES = [
    ["CLIENT",                "CLIENT"],
    ["JRE",                   "JRE"],
    ["MICROLOADER",           "MICROLOADER"],
    ["PLUGIN",                "PLUGIN"],
    ["SAM_SERVER_COMPONENT",  "SAM_SERVER_COMPONENT"],
	["CONTENT",				  "CONTENT"]
  ]
  
  CPU_BIT_TYPES = [
    ["NA",          "NA"],
    ["BITS_64",     "BITS_64"],
    ["BITS_32",     "BITS_32"]
  ]
  
  CPU_TYPES = [
    ["NA",      "NA"],
    ["X86",     "X86"],
    ["PPC",     "PPC"]
  ]
  
  OS_FAMILY_TYPES = [
    ["NA",          "NA"],
    ["WINDOWS",     "WINDOWS"],
    ["OSX",         "OSX"],
    ["LINUX",       "LINUX"]
  ]
  
  OS_SERIES_TYPES = [
    ["NA",           "NA"],
    ["WIN_2000",     "WIN_2000"],
    ["WIN_XP",       "WIN_XP"],
    ["WIN_2003",     "WIN_2003"],
    ["WIN_VISTA",    "WIN_VISTA"],
    ["MAC_10_3",     "MAC_10_3"],
    ["MAC_10_4",     "MAC_10_4"],
    ["MAC_10_5",     "MAC_10_5"]
  ]
  
  METADATA_NAMES = [
    ["-- Select one --", ""],
    ["Distribution Scope", "distributionScope"],
	["Agent IDs", "agentIds"]
  ]
  
  protected
  
  def validate
    if (self.binary_data.nil? && self.creating_file)
      errors.add("Sapling File", " must be a valid file") if (self.update_sapling_file.nil? || (self.update_sapling_file == "1"))
    end  
  end
  
end

# == Schema Information
#
# Table name: sapling
#
#  id             :integer(10)     not null, primary key
#  created_at     :datetime        not null
#  updated_at     :datetime
#  published_at   :datetime
#  sapling_code   :string(255)     not null
#  sapling_type   :string(255)
#  version        :integer(10)     not null
#  os_family      :string(255)     not null
#  os_series      :string(255)     not null
#  cpu_type       :string(255)     not null
#  cpu_bits       :string(255)     not null
#  scheduled      :boolean         not null
#  state          :string(1)       default("d"), not null
#  release_date   :datetime
#  notes          :string(2048)
#  fake           :boolean         default(FALSE), not null
#  customer_desc  :text
#  marketing_name :string(255)
#

