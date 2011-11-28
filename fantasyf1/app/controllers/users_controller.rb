class UsersController < ApplicationController
  
  layout "home" 
  # Protect these actions behind an admin login
  # before_filter :admin_required, :only => [:suspend, :unsuspend, :destroy, :purge]
  before_filter :find_user, :only => [:suspend, :unsuspend, :destroy, :purge]
  

  # render new.rhtml
  def new
    @user = User.new
  end
 
  def create
    logout_keeping_session!
    @user = User.new(params[:user])

    @user.register! if @user && @user.valid?
    success = @user && @user.valid?

    if success && @user.errors.empty?
     #  redirect_back_or_default('/')
     # flash[:notice] = "Thanks for signing up!  We're sending you an email with your activation code."
    else
      flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
      render :action => 'new'
    end
  end

  def activate
    logout_keeping_session!
    user = User.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && user && !user.active?
      user.activate!
      flash[:notice] = "Signup complete! Please sign in to continue."
      redirect_to '/login'
    when params[:activation_code].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default('/')
    else 
      flash[:error]  = "We couldn't find a user with that activation code -- check your email? Or maybe you've already activated -- try signing in."
      redirect_back_or_default('/')
    end
  end

  def suspend
    @user.suspend! 
    redirect_to users_path
  end

  def unsuspend
    @user.unsuspend! 
    redirect_to users_path
  end

  def destroy
    @user.delete!
    redirect_to users_path
  end

  def purge
    @user.destroy
    redirect_to users_path
  end
  
  # There's no page here to update or destroy a user.  If you add those, be
  # smart -- make sure you check that the visitor is authorized to do so, that they
  # supply their old password along with a new one to update it, etc.

 def change_password
      return unless request.post?
      if User.authenticate(current_user.login, params[:old_password])
        if ((params[:password] == params[:password_confirmation]) && 
                              !params[:password_confirmation].blank?)
          current_user.password_confirmation = params[:password_confirmation]
          current_user.password = params[:password]

          if current_user.save
            flash[:notice] = "Password successfully updated" 
            redirect_to :controller=>"home", :action=>"index"
          else
            flash[:alert] = "Password not changed" 
          end

        else
          flash[:alert] = "New Password mismatch" 
          @old_password = params[:old_password]
        end
      else
        flash[:alert] = "Old password incorrect" 
      end
    end

    #gain email address
    def forgot_password
      return unless request.post?
      if @user = User.find_by_email(params[:user][:email])
        @user.forgot_password
        @user.save
        redirect_back_or_default('/')
        flash[:notice] = "A password reset link has been sent to your email address" 
      else
        flash[:alert] = "Could not find a user with that email address" 
      end
    end

    #reset password
    def reset_password
      @user = User.first(:conditions => ["password_reset_code = ? AND password_reset_code IS NOT NULL", params[:id]])
      return unless params[:user]

      if ((params[:user][:password] && params[:user][:password_confirmation]) && 
                              !params[:user][:password_confirmation].blank?)
        self.current_user = @user #for the next two lines to work
        current_user.password_confirmation = params[:user][:password_confirmation]
        current_user.password = params[:user][:password]
        @user.reset_password
        flash[:notice] = current_user.save ? "Password reset success." : "Password reset failed." 
        redirect_back_or_default('/')
      else
        flash[:alert] = "Password mismatch" 
      end  
    end
  
    def show
      @user = User.find_by_login(params[:id])
      
      @tracks = Track.find(:all,:order => 'qualify_time ASC')

  @comingtrack = Track.first(:order => 'qualify_time ASC', :conditions => ['qualify_time > ? ',Time.now])
  
  if (@comingtrack)
    @d_year = @comingtrack.qualify_time.year()
    @d_month = @comingtrack.qualify_time.month()-1
    @d_day = @comingtrack.qualify_time.day()
    @d_hour = @comingtrack.qualify_time.hour()
    @d_minut = @comingtrack.qualify_time.min()
    @d_second = @comingtrack.qualify_time.sec()
  end 
      
      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @track }
      end
    end

  protected
    def find_user
      @user = User.find(params[:id])
    end
  
end
