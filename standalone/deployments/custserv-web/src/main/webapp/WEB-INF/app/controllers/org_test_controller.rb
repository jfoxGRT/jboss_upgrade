class OrgTestController < ApplicationController

layout 'cs_layout'

def index
end

def find_orgs
  @search_results = Org.find(:all, :conditions => ["name like ?", params[:org][:name]+"%"])
end

end