class AlertCart
  attr_reader :alert_instance_items
  
  def initialize
    @alert_instance_items = []
  end
  
  def add_alert(pAlertInstance)
    @alert_instance_items << pAlertInstance
  end
  
  def remove_alert(pAlertInstance)
    @alert_instance_items.delete(pAlertInstance)
  end
  
  def contains(pAlertInstance)
    if (@alert_instance_items.include?(pAlertInstance))
      return true
    else
      return false
    end
  end
  
  def print
    puts "ALERT CART"
    @alert_instance_items.each do |aii|
      puts "Alert Instance Item: {id=" + aii.id.to_s + "}"
    end
  end
  
  def size
    return @alert_instance_items.length
  end
    
end
