require 'rexml/document'
include REXML
class EsbMessage < ActiveRecord::Base
  set_table_name "esb_message"
  
  belongs_to :esb_message_src_system
  
  
  @@MESSAGE_SOURCES = [["CSI", "CSI.DATA.XML.IN"], ["TMS", "TMS.DATA.XML.IN"]]
  
  @@INBOUND_MESSAGE_CLASSES = [
  ["ContactAddressMessage", "ContactAddressMessage"],
  ["ContactEmailMessage", "ContactEmailMessage"],
  ["ContactPhoneMessage", "ContactPhoneMessage"],
  ["CustomerClassMessage", "CustomerClassMessage"],
  ["CustomerRelationshipMessage", "CustomerRelationshipMessage"],
  ["CustomerRoleMessage", "CustomerRoleMessage"],
  ["CustomerStatusMessage", "CustomerStatusMessage"],
  ["EndOrganizationMessage", "EndOrganizationMessage"],
  ["EntitlementLicenseMessage", "EntitlementLicenseMessage"],
  ["EntitlementMessage", "EntitlementMessage"],
  ["IndivNameMessage", "IndivNameMessage"],
  ["MoveRelationshipMessage", "MoveRelationshipMessage"],
  ["NewEduOrganizationMessage", "NewEduOrganizationMessage"],
  ["NewOrganizationMessage", "NewOrganizationMessage"],
  ["OrgClassificationMessage", "OrgClassificationMessage"],
  ["OrgIdentificationMessage", "OrgIdentificationMessage"],
  ["SourceCustomerStatusMessage", "SourceCustomerStatusMessage"],
  ["SourceReferenceMessage", "SourceReferenceMessage"]
  ]
  
  def self.MESSAGE_SOURCES
    @@MESSAGE_SOURCES
  end
  
  def self.find_by_audit_message_params(sam_customer_id, message_class, resource_prefix, resource_id)
    EsbMessage.find(:all, :select => "distinct em.*", :joins => "em inner join audit_message am on em.reference_message_token = am.token",
                    :conditions => ["am.sam_customer_id = ? and am.clazz = ? and am.resource_id = ?", sam_customer_id, message_class, resource_prefix + resource_id])
  end
  
  
  def root_element_name
    message_path_prefix = "sami.message.msg.impl."
    if (self.message_class == (message_path_prefix + "NewEduOrganizationMessage"))
      return "CODEM_NEW_EDU_ORGANIZATION"
    elsif (self.message_class == (message_path_prefix + "EntitlementMessage"))
      return "CODEM_ENTITLEMENT"
    elsif (self.message_class == (message_path_prefix + "NewIndividualMessage"))
      return "CODEM_NEW_INDIVIDUAL"
    end
  end
  
  def simple_class_name
    name = self.message_class
    i = name.rindex('.')
    return name if i.nil?
    name.slice(i+1,name.length-1)
  end
  
  def corp_id
    Document.new(self.message_text).root.elements["/" + self.root_element_name + "/IDENTIFIERS/CORP_INFO/CORP_ID_VALUE"].get_text.value
  end
  
  def self.search(params)
    conditions_clause_str = ""
    #conditions_clause_str = "queue_name = ?"
    conditions_clause_fillins = []
    if (!params[:corpid_value].empty?)
      conditions_clause_str += " and " if !conditions_clause_str.empty?
      conditions_clause_str += "corpid_value = ?"
      conditions_clause_fillins << params[:corpid_value]
    end
    if (params[:ignored] == "1")
      conditions_clause_str += " and " if !conditions_clause_str.empty?
      conditions_clause_str += "ignored is not null"
    end
    return EsbMessage.find(:all, :select => "id, message_timestamp, message_class, corpid_value, received, parsed, handled, ignored, exception_class", :conditions => [conditions_clause_str, conditions_clause_fillins].flatten, :order => "message_timestamp desc")
  end
  
end

# == Schema Information
#
# Table name: esb_message
#
#  id                        :integer(10)     not null, primary key
#  correlation_id            :string(255)
#  delivery_mode             :integer(10)
#  message_id                :string(255)
#  message_timestamp         :datetime
#  message_text              :text
#  message_type              :string(255)
#  message_class             :string(255)
#  received                  :datetime
#  parsed                    :datetime
#  handled                   :datetime
#  ignored                   :datetime
#  held                      :datetime
#  queue_name                :string(255)
#  corpid_value              :string(255)
#  exception_class           :string(255)
#  transaction_type          :string(255)
#  esb_message_src_system_id :integer(10)
#  transaction_date          :datetime
#  msg_info_type             :string(255)
#  reference_message_token   :string(255)
#

