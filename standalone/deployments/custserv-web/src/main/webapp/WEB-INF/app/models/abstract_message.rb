require 'rexml/document'
include REXML
class EsbMessage < ActiveRecord::Base
  set_table_name "esb_message" 
  
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
  
  def self.print_message_info(msg_txt)
    begin
      split_txt = msg_txt.split(/<\/?TRANSACTION_DATE>/)
      transaction_time_str = split_txt[1].strip
      split_txt = msg_txt.split(/<\/?CORP_ID_VALUE>/)
      corp_id_value = split_txt[1].strip
      trans_type_seg = msg_txt.split('TRANSACTION_TYPE="')[1]
      quote_index = trans_type_seg.index('"')
      transaction_type = trans_type_seg.slice(0, quote_index)
      logger.info "Message Name: #{msg_txt.slice(/<CODEM_[A-Za-z0-9_]*>/)}"
      logger.info "Transaction Type: #{transaction_type}"
      logger.info "CORP_ID_VALUE: #{corp_id_value}"
      logger.info "Transaction Date: #{transaction_time_str}"
      logger.info "Length of Message: #{msg_txt.length}"
      logger.info "Message Hash: #{msg_txt.hash}"
    rescue
      logger.info "ERROR: Invalid CoDEM message:"
      logger.info msg_txt
    end
  end
  
  #def transaction_time
  #  msg_txt = self.message_text
  #  return nil if msg_txt.index('<TRANSACTION_DATE>').nil?
  #  split_txt = msg_txt.split(/<\/?TRANSACTION_DATE>/)
  #  return nil if (split_txt.length != 3)
  #  transaction_time_str = split_txt[1].strip
  #  transaction_time_str[10] = 'T'
  #  begin
  #    tt = Time.xmlschema(transaction_time_str)
  #  rescue ArgumentError
  #    return nil
  #  else
  #    return tt
  #  end
  #end
  
  def self.message_name(msg_txt)
    return msg_txt.slice(/<CODEM_[A-Za-z0-9_]*>/)
  end
  
  #def transaction_type
  #  msg_txt = self.message_text
  #  trans_type_seg = msg_txt.split('TRANSACTION_TYPE="')[1]
  #  quote_index = trans_type_seg.index('"')
  #  return trans_type_seg.slice(0, quote_index)
  #end
  
  #def corp_id
  #  msg_txt = self.message_text
  #  return nil if msg_txt.index('<CORP_ID_VALUE>').nil?
  #  split_txt = msg_txt.split(/<\/?CORP_ID_VALUE>/)
  #  return nil if (split_txt.length != 3)
  #  return split_txt[1].strip
    #Document.new(self.message_text).root.elements["/" + self.root_element_name + "/IDENTIFIERS/CORP_INFO/CORP_ID_VALUE"].get_text.value
  #end
  
end
