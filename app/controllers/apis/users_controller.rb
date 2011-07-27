class Apis::UsersController < ApplicationController
  skip_before_filter :check_if_login_required

  # authenticate
  def authenticate
    
    @user = User.try_to_login(params[:username], params[:password])

    respond_to do |format|
      if !@user.nil? && !@user.new_record?
        format.html
        format.xml { render :xml => @user, :status => :ok}
        format.json { render :json => @user}
      else
        format.html
        format.xml { render :xml => "Invalid user.", :status => "401" }
        format.json { render :json => {:message => "Invalid user.", :status => "401"}, :status => 402 }
      end
    
    end
  end

end
