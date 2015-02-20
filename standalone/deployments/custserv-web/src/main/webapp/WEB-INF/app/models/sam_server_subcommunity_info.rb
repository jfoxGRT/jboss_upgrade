class SamServerSubcommunityInfo < ActiveRecord::Base
  set_table_name "sam_server_subcommunity_info"
  belongs_to :sam_server_community_info
  belongs_to :subcommunity
  
  def snapshot_for_initial_registration
    SnapshotServerLicenseCount.find(:first, :conditions => ["sam_server_id = ? and subcommunity_id = ? and event_type = ?", self.sam_server_community_info.sam_server.id, self.subcommunity_id, SnapshotServerLicenseCount.INITIAL_REGISTRATION_CODE])
  end
  
  #==============================================
  #       Seat Terminology
  #  SAM Server  --- SAM Connect
  #  -------------------------------------------
  #  Allocated   --- Licensed Seats
  #  Enrolled    --- Used Seats
  #  Available   --- <calculated> calling Unused
  # 
  #  * Using "SAM Server" terminology in method 
  #    names to better integrate development with
  #    the view part of MVC.
  #==============================================

  #==============================================
  # Multiple Server Totals
  #==============================================
  def self.count_allocated_servers_total( product, samCustomer )
    sql = <<EOS
  select sum(ss_sc.licensed_seats) as cnt from sam_server_subcommunity_info ss_sc
    inner join subcommunity sc on ss_sc.subcommunity_id = sc.id
    inner join product p on sc.product_id = p.id
    inner join sam_server_community_info ss_c on ss_sc.sam_server_community_info_id = ss_c.id
    inner join sam_server ss on ss_c.sam_server_id = ss.id
  where p.id = #{product.id} and ss.sam_customer_id = #{samCustomer.id} and ss.status = 'a'
EOS
    results = ActiveRecord::Base.connection.select_one sql
    (results['cnt'].nil?) ? 0 : results['cnt']     
  end
   
  def self.count_enrolled_servers_total( product, samCustomer )
    sql = <<EOS
  select sum(ss_sc.used_seats) as cnt from sam_server_subcommunity_info ss_sc
    inner join subcommunity sc on ss_sc.subcommunity_id = sc.id
    inner join product p on sc.product_id = p.id
    inner join sam_server_community_info ss_c on ss_sc.sam_server_community_info_id = ss_c.id
    inner join sam_server ss on ss_c.sam_server_id = ss.id 
  where p.id = #{product.id} and ss.sam_customer_id = #{samCustomer.id} and ss.status = 'a'   
EOS
    results = ActiveRecord::Base.connection.select_one sql
    (results['cnt'].nil?) ? 0 : results['cnt']     
  end
  
  def self.count_available_servers_total( product, samCustomer )
    sql = <<EOS
  select sum(ss_sc.licensed_seats - ss_sc.used_seats) as cnt from sam_server_subcommunity_info ss_sc
    inner join subcommunity sc on ss_sc.subcommunity_id = sc.id
    inner join product p on sc.product_id = p.id
    inner join sam_server_community_info ss_c on ss_sc.sam_server_community_info_id = ss_c.id
    inner join sam_server ss on ss_c.sam_server_id = ss.id
  where p.id = #{product.id} and ss.sam_customer_id = #{samCustomer.id} and ss.status = 'a'
EOS
    results = ActiveRecord::Base.connection.select_one sql
    (results['cnt'].nil?) ? 0 : results['cnt']     
  end

   
  #==============================================
  # Single Server Totals
  #==============================================
  def self.count_allocated_server( product, server )
    sql = <<EOS
  select sum(ss_sc.licensed_seats) as cnt from sam_server_subcommunity_info ss_sc
    inner join subcommunity sc on ss_sc.subcommunity_id = sc.id
    inner join product p on sc.product_id = p.id
    inner join sam_server_community_info ss_c on ss_sc.sam_server_community_info_id = ss_c.id
  where p.id = #{product.id} and ss_c.sam_server_id = #{server.id}
EOS
    results = ActiveRecord::Base.connection.select_one sql
    (results['cnt'].nil?) ? 0 : results['cnt']     
  end
  
  
  def self.count_enrolled_server( product, server )
    sql = <<EOS
  select sum(ss_sc.used_seats) as cnt from sam_server_subcommunity_info ss_sc
    inner join subcommunity sc on ss_sc.subcommunity_id = sc.id
    inner join product p on sc.product_id = p.id
    inner join sam_server_community_info ss_c on ss_sc.sam_server_community_info_id = ss_c.id
  where p.id = #{product.id} and ss_c.sam_server_id = #{server.id}
EOS
    results = ActiveRecord::Base.connection.select_one sql
    (results['cnt'].nil?) ? 0 : results['cnt']     
  end
  
  def self.count_available_server( product, server )
    sql = <<EOS
  select sum(ss_sc.licensed_seats - ss_sc.used_seats) as cnt from sam_server_subcommunity_info ss_sc
    inner join subcommunity sc on ss_sc.subcommunity_id = sc.id
    inner join product p on sc.product_id = p.id
    inner join sam_server_community_info ss_c on ss_sc.sam_server_community_info_id = ss_c.id
  where p.id = #{product.id} and ss_c.sam_server_id = #{server.id}
EOS
    results = ActiveRecord::Base.connection.select_one sql
    (results['cnt'].nil?) ? 0 : results['cnt']     
  end
  
  def self.counts_compared_with_seat_pool(sam_customer_id, subcommunity_id)
    find_by_sql(["select sp.id as pool_id, ss.id as server_id, ss.installation_code, ss.server_type, sssi.id as sssi_id, ss.name as server_name, ss.clone_parent_id, ss.agg_server,
                  sp.seat_count as pool_count, sssi.licensed_seats as server_allocated_count, sssi.used_seats as server_enrolled_count,
                  sa.id as seat_activity_id, sa.delta as delta from sam_server_subcommunity_info sssi
                  inner join sam_server_community_info ssci on sssi.sam_server_community_info_id = ssci.id
                  left join sam_server ss on ssci.sam_server_id = ss.id
                  left join seat_pool sp on (sp.sam_customer_id = ss.sam_customer_id and sp.subcommunity_id = sssi.subcommunity_id and sp.sam_server_id = ss.id)
                  left join seat_activity sa on (sa.seat_pool_id = sp.id and sa.status = 0)
                  where ss.sam_customer_id = ? and sssi.subcommunity_id = ? and ss.status = 'a' order by server_name", sam_customer_id, subcommunity_id])
  end
  
  def self.find_by_sam_server_and_subcommunity(sam_server, subcommunity)
    SamServerSubcommunityInfo.find(:first, :select => "sssi.*", :joins => "sssi inner join sam_server_community_info ssci on sssi.sam_server_community_info_id = ssci.id \
                                                      inner join sam_server ss on ssci.sam_server_id = ss.id", 
                                           :conditions => ["ss.id = ? and sssi.subcommunity_id = ?", sam_server.id, subcommunity.id])
  end
  
  def self.enrolled_seat_count_on_server( server, subcom )
    sql = <<EOS
  select sum(sssi.used_seats) as cnt from sam_server_subcommunity_info sssi
    inner join subcommunity sc on sssi.subcommunity_id = sc.id
    inner join sam_server_community_info ssci on sssi.sam_server_community_info_id = ssci.id
  where sssi.subcommunity_id = #{subcom.id} and ssci.sam_server_id = #{server.id}
EOS
    results = ActiveRecord::Base.connection.select_one sql
    (results['cnt'].nil?) ? 0 : results['cnt']     
  end

  
end

# == Schema Information
#
# Table name: sam_server_subcommunity_info
#
#  id                           :integer(10)     not null, primary key
#  sam_server_community_info_id :integer(10)     not null
#  subcommunity_id              :integer(10)     not null
#  licensed_seats               :integer(10)     default(0)
#  used_seats                   :integer(10)     default(0)
#  created_at                   :datetime
#  updated_at                   :datetime
#  sourced_by                   :string(1)       default("c"), not null
#

