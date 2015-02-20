#
# Add your queue definitions here
#
ActiveMessaging::Gateway.define do |s|
  #s.connection_configuration = {:reliable => true}
  #s.queue :orders, '/queue/Orders'
  #s.processor_group :group1, :order_processor
  
  # Captures our internal Scholastic Application Topic
  s.queue :scholastic_application, '/topic/Scholastic.Application'

  # The 5 internal Scholastic Queues
  s.queue :csi_inbound, '/queue/CSI.DATA.XML.IN'
  s.queue :csi_outbound, '/queue/CSI.DATA.XML.OUT'
  s.queue :csi_response, '/queue/CSI.DATA.XML.RES'
  s.queue :tms_inbound, '/queue/TMS.DATA.XML.IN'
  s.queue :tms_outbound, '/queue/TMS.DATA.XML.OUT'
  
end