module AgentsHelper
  
  def getHostName(pAgent)
    return nil
    #return nil if pAgent.nil?
    #agentSocket = Socket.gethostbyname(pAgent.last_ip)
    return nil if agentSocket.nil?
    return agentSocket[0] if (agentSocket.length > 0)
    return nil
  end

end
