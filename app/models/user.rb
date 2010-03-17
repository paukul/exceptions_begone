require 'net/ldap'

class User
  include MongoMapper::Document
  
  key :username
  key :email
  key :crypted_password
  key :password_salt
  key :password_salt
  key :login_count
  key :current_login_at
  key :last_login_at
  timestamps!

  has_many :stacks
  
  # acts_as_authentic do |authlogic|
    # authlogic.validate_password_field = false if AUTHLOGIC_ADDON == "ldap"
  # end

  protected
    def valid_ldap_credentials?(password_plaintext)
      # add your ldap configuration here
      ldap = Net::LDAP.new
      ldap.host = "your host name"
      ldap.port = 636 #required for SSL connections, 389 is the default plain text port
      ldap.encryption :simple_tls #also required to tell Net:LDAP that we want SSL
      ldap.base = "your base settings" 

      ldap.auth "#{self.username}@your_host","#{password_plaintext}"
      ldap.bind # will return false if authentication is NOT successful
    end
end
