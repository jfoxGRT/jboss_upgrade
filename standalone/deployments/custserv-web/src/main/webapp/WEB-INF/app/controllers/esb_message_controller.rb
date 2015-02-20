require 'rexml/document'
require 'rexml/formatters/pretty'
require 'date'
include REXML
class EsbMessageController < ApplicationController

  #layout 'new_layout_with_jeff_stuff_and_date'
  layout "default"

  def index
      @date = Date.today.to_s
      @src_system_list = [["-any-", nil]].concat(EsbMessageSrcSystem.find(:all, :order => "name").collect {|emss| [emss.name, emss.id]})
      conditionClause = "message_timestamp between '#{@date} 00:00:00' and '#{@date} 23:59:59'"
      esb_messages = EsbMessage.find(:all, :select => "queue_name, message_timestamp, message_class, ignored", :conditions => conditionClause, :order => "message_timestamp desc")
      @last_esb_message_received = EsbMessage.find(:first, :conditions => "received is not null", :order => "id desc")
      @last_esb_message_sent = EsbMessage.find(:first, :conditions => "received is null", :order => "id desc")
      @esb_inbound_message_hash = {}
      @esb_outbound_message_hash = {}
      esb_messages.each do |e|
        if(!e.queue_name.nil? && e.queue_name.include?(".OUT"))
          elem = @esb_outbound_message_hash[e.message_class]
          @esb_outbound_message_hash[e.message_class] = EsbMessageArray.new if elem.nil?
          @esb_outbound_message_hash[e.message_class] << e
          (@esb_outbound_message_hash[e.message_class].num_ignored = @esb_outbound_message_hash[e.message_class].num_ignored + 1) if (!e.ignored.nil?)
        else
          elem = @esb_inbound_message_hash[e.message_class]
          @esb_inbound_message_hash[e.message_class] = EsbMessageArray.new if elem.nil?
          @esb_inbound_message_hash[e.message_class] << e
          (@esb_inbound_message_hash[e.message_class].num_ignored = @esb_inbound_message_hash[e.message_class].num_ignored + 1) if (!e.ignored.nil?)
        end 
      end
      @prototype_required = true
      @date_selector_support = true
      #@app_topic_message_hash = {}
      #conditionClause = "message_timestamp between '#{@date} 00:00:00' and '#{@date} 23:59:59'"
      #app_topic_messages = AuditMessage.find(:all, :conditions => conditionClause)
      #@sumAppTopicMessages = app_topic_messages.length
      #app_topic_messages.each do |am|
      #  classCategory = @app_topic_message_hash[am.clazz]
      #  @app_topic_message_hash[am.clazz] = Array.new if classCategory.nil?
      #  @app_topic_message_hash[am.clazz] << am
      #end
    
  end
  
  def find_messages
      puts "params: #{params.to_yaml}"
      @date = params[:esb_message_date].to_s
      @last_esb_message_received = EsbMessage.find(:first, :conditions => "received is not null", :order => "id desc")
      @last_esb_message_sent = EsbMessage.find(:first, :conditions => "received is null", :order => "id desc")
      conditionClause = "message_timestamp between '#{@date} 00:00:00' and '#{@date} 23:59:59'"
      esb_messages = EsbMessage.find(:all, :select => "queue_name, message_timestamp, message_class, ignored", :conditions => conditionClause, :order => "message_timestamp desc")
      @esb_inbound_message_hash = {}
      @esb_outbound_message_hash = {}
      esb_messages.each do |e|
        if(!e.queue_name.nil? && e.queue_name.include?(".OUT"))
          elem = @esb_outbound_message_hash[e.message_class]
          @esb_outbound_message_hash[e.message_class] = EsbMessageArray.new if elem.nil?
          @esb_outbound_message_hash[e.message_class] << e
          (@esb_outbound_message_hash[e.message_class].num_ignored = @esb_outbound_message_hash[e.message_class].num_ignored + 1) if (!e.ignored.nil?)
        else
          elem = @esb_inbound_message_hash[e.message_class]
          @esb_inbound_message_hash[e.message_class] = EsbMessageArray.new if elem.nil?
          @esb_inbound_message_hash[e.message_class] << e
          (@esb_inbound_message_hash[e.message_class].num_ignored = @esb_inbound_message_hash[e.message_class].num_ignored + 1) if (!e.ignored.nil?)
        end 
      end
      
      #@app_topic_message_hash = {}
      #conditionClause = "date(timestamp) = '#{@date}'"
      #app_topic_messages = AuditMessage.find(:all, :conditions => conditionClause)
      #@sumAppTopicMessages = app_topic_messages.length
      #app_topic_messages.each do |am|
      #  classCategory = @app_topic_message_hash[am.clazz]
      #  @app_topic_message_hash[am.clazz] = Array.new if classCategory.nil?
      #  @app_topic_message_hash[am.clazz] << am
      #end
      
  end
  
  def find_messages_by_reference_token
    @esb_messages = EsbMessage.find_all_by_reference_message_token(params[:id])
    render(:layout => "cs_blank_layout")
  end
  
  def find_by_audit_message_params
    @esb_messages = EsbMessage.find_by_audit_message_params(params[:sam_customer_id], params[:message_class], params[:resource_prefix], params[:resource_id])
    render(:template => "/esb_message/find_messages_by_reference_token", :layout => "cs_blank_layout")
  end
  
  def app_topic_message_class
    puts "the date: " + params[:message_time].to_s
    @messageList = AuditMessage.find(:all, :conditions => ["date(timestamp) = date(?) and clazz = ?", params[:message_time].to_s, params[:message_type]], :order => "timestamp desc")
    render(:layout => "cs_blank_layout")
  end
  
  def app_topic_message_detail
    @message = AuditMessage.find(params[:id])
    @message_props = @message.audit_message_props
    render(:layout => "cs_blank_layout")
  end
  
  def inbound_message_class
    conditionsClause = "message_timestamp between '#{params[:filter_date]} 00:00:00' and '#{params[:filter_date]} 23:59:59' and message_class = '#{params[:message_type]}' and received is not null"
    @esb_messages = EsbMessage.find(:all, :conditions => conditionsClause, :order => "message_timestamp desc")
    render(:layout => "cs_blank_layout")
  end
  
  def outbound_message_class
    conditionsClause = "message_timestamp between '#{params[:filter_date]} 00:00:00' and '#{params[:filter_date]} 23:59:59' and message_class = '#{params[:message_type]}' and received is null"
    @esb_messages = EsbMessage.find(:all, :conditions => conditionsClause, :order => "message_timestamp desc")
    render(:layout => "cs_blank_layout")
  end
  
  
  def message_detail
    @theMessage = EsbMessage.find(params[:id])
    #doc = Document.new(@theMessage.message_text)
	doc = Document.new(@theMessage.message_text)
	@message_output = ""
	#REXML::Formatters::Pretty.new.write_document(doc.root, @message_output)
    #@message_output = pretty_xml(doc)
	doc.write(@message_output, 4 )
    render(:layout => "cs_blank_layout")
  end
  
  private 
    
	def pretty_print(parent_node, itab)
    buffer = ''

    parent_node.elements.each do |node|

      buffer += ' ' * itab + "<#{node.name}#{get_att_list(node)}"
  
      if node.to_a.length > 0
        buffer += ">"
        if node.text.nil?
          buffer += "\n"
          buffer += pretty_print(node,itab+4) 
          buffer += ' ' * itab + "</#{node.name}>\n"
        else
          node_text = node.text.strip
          if node_text != ''
            buffer += node_text 
            buffer += "</#{node.name}>\n"        
          else
            buffer += "\n" + pretty_print(node,itab+4) 
            buffer += ' ' * itab + "</#{node.name}>\n"        
          end
        end
      else
        buffer += "/>\n"
      end
      
    end
    buffer
  end

  def get_att_list(node)
    att_list = ''
    node.attributes.each { |attribute, val| att_list += " #{attribute}='#{val}'" }
    att_list
  end
  
  def pretty_xml(doc)
	logger.info("our doc type is: #{doc.class}")
	hello = doc.root
    buffer = ''
    xml_declaration = doc.to_s.match('<\?.*\?>').to_s
    buffer += "#{xml_declaration}\n" if not xml_declaration.nil?
    xml_doctype = doc.to_s.match('<\!.*\">').to_s
    buffer += "#{xml_doctype}\n" if not xml_doctype.nil?
    #buffer += "<#{doc.root.name}#{get_att_list(doc.root)}"
    if doc.root.to_a.length > 0
      buffer +=">\n#{pretty_print(doc.root,4)}</#{doc.root.name}>"
    else
      buffer += "/>\n"
    end
  end
  
  
end

class EsbMessageArray < Array

  attr_reader :num_ignored
  
  def initialize
    @num_ignored = 0
  end
  
  def num_ignored=(new_count)
    @num_ignored = new_count
  end

end
