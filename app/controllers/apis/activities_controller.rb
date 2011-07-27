# To change this template, choose Tools | Templates
# and open the template in the editor.

class Apis::ActivitiesController < ApplicationController
  skip_before_filter :check_if_login_required
  before_filter :authenticate

  def index
    @activity = Redmine::Activity::Fetcher.new(@user)

    respond_to do |format|
      format.html
      
    end
  end
end
