# Create a Hierarchy - One District and Four Schools

users = User.find(:all)
User.delete(users)

#delete the customer relationships
relationships = CustomerRelationship.find_by_sql("select cr.* from customer_relationship cr, customer c where (cr.customer_id=c.id or cr.related_customer_id=c.id) and c.ucn like '11111111_'")
CustomerRelationship.delete(relationships)
#relationships.each do |r|
#  CustomerRelationship.delete_all(r.id)
#end

seats = Seat.find(:all)
Seat.delete( seats )

#delete ALL seats and entitlements
entitlements = Entitlement.find(:all)
Entitlement.delete( entitlements )

#delete the agents and sam servers
SamServer.find(:all).each do |s|
  Agent.delete_all(["sam_server_id = ?", s.id])
  SamServer.delete_all(s.id)
end

organizations = Org.find_by_sql("select oc.* from org oc, customer c where oc.customer_id = c.id and c.ucn like '11111111_'")
Org.delete(organizations)

#delete the individual relationship
relationships = CustomerRelationship.find_by_sql("select cr.* from customer_relationship cr, customer c where (cr.customer_id=c.id or cr.related_customer_id=c.id) and c.ucn = 1111111116")
CustomerRelationship.delete(relationships)

#delete the individual's role
role = CustomerRole.find_by_sql("select cr.* from customer_role cr, customer c where cr.related_customer_id = c.id and c.ucn = 1111111116")
CustomerRole.delete(role)

#delete all users
users = User.find(:all)
User.delete(users)

#delete the individual
individual = IndividualCustomer.find_by_sql("select ic.* from individual_customer ic, customer c where ic.customer_id = c.id and c.ucn = 1111111116")
IndividualCustomer.delete(individual)

customers = Customer.find_by_sql("select * from customer where ucn like '11111111_' or ucn like '111111111_'")
Customer.delete(customers)

