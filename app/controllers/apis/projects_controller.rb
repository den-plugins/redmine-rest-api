
class Apis::ProjectsController < ApplicationController
  skip_before_filter :check_if_login_required
  before_filter :authenticate

  def index
    @projects = @user.projects
    respond_to do |format|
      format.html
      format.xml { render :xml => @projects.to_xml(
          :include => {
            :members => {
              :include => {
                :user => {:only => [:id, :login, :firstname, :lastname, :mail, :status]},
                :role => {:only => [:id, :name]}
              }
            }
          }), :status => :ok}

      format.json { render :json => @projects.to_json(
          :include => {
            :members => {
              :include => {
                :user => {:only => [:id, :login, :firstname, :lastname, :mail, :status]},
                :role => {:only => [:id, :name]}
              }
            }
          })}
    end
  end

  def show
    @project = Project.find(params[:id])
    respond_to do |format|
      format.html
      format.xml { render :xml => @project.to_xml(:include => {:issues => {:include => [:author]}}) }
      format.json { render :xml => @project.to_json(:include => {:issues => {:include => [:author]}}) }
    end
  end

  #get all maintenance information being used by the project
  def maintenances
    @project = Project.find(params[:id])
    @trackers = @project.trackers
    @issue_categories = @project.issue_categories
    @versions = @project.versions
    @issue_statuses = IssueStatus.all
    @issue_priorities = Enumeration.find_all_by_opt("IPRI")
    result = {'trackers' => @trackers, 'statuses' => @issue_statuses, 'versions' => @versions,
      'categories' => @issue_categories, 'priorities' => @issue_priorities}

    respond_to do |format|
      format.html
      format.xml { render :xml => result, :status => :ok}
      format.json { render :json => result }
    end

  end

  private

=begin
  def require_authentication
    @user = find_current_user
    if @user.nil?
      respond_to do |format|
        format.html { redirect_to :controller => "account", :action => "login", :back_url => url_for(params) }
        format.xml { render :xml => "user authentication required.", :status => '401' }
      end
      return false
    end
  end
=end
  
end
