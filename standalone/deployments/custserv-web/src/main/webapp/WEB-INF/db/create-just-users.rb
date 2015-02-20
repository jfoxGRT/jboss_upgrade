# ONLY USERS and PERMISSIONS

theRootOrg=Org.find(11)

# Create Users
user1 = User.new(
:email => "samuser1@discursive.com",
:password => "password",
:password_confirmation => "password",
:first_name => "One",
:last_name => "User",
:org => theRootOrg )
user1.sxave!
user2 = User.new(
:email => "samuser2@discursive.com",
:password => "password",
:password_confirmation => "password",
:first_name => "Two",
:last_name => "User",
:org => theRootOrg )
user2.save!
user3 = User.new(
:email => "samuser3@discursive.com",
:password => "password",
:password_confirmation => "password",
:first_name => "Three",
:last_name => "User",
:org => theRootOrg )
user3.save!
user4 = User.new(
:email => "samuser4@discursive.com",
:password => "password",
:password_confirmation => "password",
:first_name => "Four",
:last_name => "User",
:org => theRootOrg )
user4.save!

userPermission = Permission.find_by_code("USER")
licensePermission = Permission.find_by_code("LICENSE")
serverPermission = Permission.find_by_code("SERVER")

user1.permissions << userPermission
user1.permissions << licensePermission
user1.permissions << serverPermission
user1.save!

user2.permissions << userPermission
user2.permissions << licensePermission
user2.save!

user3.permissions << userPermission
user3.save!

