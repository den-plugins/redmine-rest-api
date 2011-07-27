module ApplicationMethods
  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @user = User.try_to_login(username, password)
      respond_to do |format|
        if !@user.nil? && !@user.new_record?
          format.html { return true }
          format.xml { return true }
          format.json { return true }
        else
          format.html { redirect_to "/login" }
          format.xml do
            render :xml => "user authentication required.", :status => '401'
            return false
          end
          format.json do
            render :json => "user authentication required.", :status => '401'
            return false
          end
        end
      end
    end
  end
end
