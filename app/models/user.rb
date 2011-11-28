require 'digest/sha1'

class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken

  include Authorization::StatefulRoles
  validates_presence_of     :login
  validates_length_of       :login,    :within => 2..40
  validates_uniqueness_of   :login
  validates_format_of       :login,    :with => Authentication.login_regex, :message => Authentication.bad_login_message

  validates_presence_of     :email
  validates_length_of       :email,    :within => 6..100 #r@a.wk
  validates_uniqueness_of   :email
  validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message

  

  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :password, :password_confirmation, :password_reset_code, :state, :activation_code



  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.  
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_in_state :first, :active, :conditions => {:login => login.downcase} # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end

    def forgot_password
      @forgotten_password = true
      self.make_password_reset_code
    end

    def reset_password
      # First update the password_reset_code before setting the 
      # reset_password flag to avoid duplicate email notifications.
      update_attributes(:password_reset_code => nil)
      @reset_password = true
    end  

    #used in user_observer
    def recently_forgot_password?
      @forgotten_password
    end
    
    def recently_reset_password?
      @reset_password
    end
    
    def recently_activated?
      @recent_active
    end
  
  protected
      def make_password_reset_code
        self.password_reset_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
      end
    
      def make_activation_code
    
        self.deleted_at = nil
    
        self.activation_code = self.class.make_token
      end
  
end
