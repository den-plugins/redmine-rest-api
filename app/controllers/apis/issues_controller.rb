class Apis::IssuesController < ApplicationController
  skip_before_filter :check_if_login_required
  before_filter :authenticate
  before_filter :setup_controller

  def index
    last_update = Time.parse(params[:lu]) if params[:lu]
    if last_update
      @issues = @project.issues.find(:all, :conditions => ["updated_on > ?",last_update.utc? ? last_update.localtime : last_update])
    else
      @issues = @project.issues
    end

    respond_to do |format|
      format.html

      format.xml { render :xml => @issues.to_xml(:include => {:attachments => {:only => [:id, :description, :filename], :methods => [:download_url]}, :author => {:only => [:id, :lastname, :firstname]},
          :assigned_to => {:only => [:id, :lastname, :firstname]}},
          :methods => [:spent_hours]) }

      format.json { render :json => @issues.to_json(:include => {:attachments => {:only => [:id, :description, :filename], :methods => [:download_url]}, :author => {:only => [:id, :lastname, :firstname]},
          :assigned_to => {:only => [:id, :lastname, :firstname]}},
          :methods => [:spent_hours]) }
    end
  end

  #create new ticket
  def create
    hours = 0.0
    if params[:issue].has_key?(:log_time)
      hours = Float(params[:issue][:log_time])  
      params[:issue].delete(:log_time)      
    end
    @issue = @project.issues.build(params[:issue])        
    @issue.author = @user
    
    respond_to do |format|
      if @issue.save       
        if hours != 0.0
          @time_entry = TimeEntry.new(:project => @project, :issue => @issue, :user => @user, :spent_on => Date.today)
          time_entry_clone = @time_entry.clone
          @time_entry.activity_id = 8
          @time_entry.hours = hours
          TimeEntry.transaction do
            if @time_entry.save
              total_time_entry = TimeEntry.sum(:hours, :conditions => "issue_id = #{@issue.id}")
              journal = @time_entry.init_journal(@user)
              journal.details << JournalDetail.new(:property => 'timelog', :prop_key => 'hours', :old_value => (time_entry_clone.hours if time_entry_clone.hours != @time_entry.hours), :value => @time_entry.hours)
              journal.details << JournalDetail.new(:property => 'timelog', :prop_key => 'activity_id', :old_value => (time_entry_clone.activity_id if !time_entry_clone.activity_id.eql?(@time_entry.activity_id)), :value => @time_entry.activity_id)
              journal.details << JournalDetail.new(:property => 'timelog', :prop_key => 'spent_on', :old_value => (time_entry_clone.spent_on if !time_entry_clone.spent_on.eql?(@time_entry.spent_on)), :value => @time_entry.spent_on)
              if !@issue.estimated_hours.nil?
                remaining_estimate = @issue.estimated_hours - total_time_entry
                journal.details << JournalDetail.new(:property => 'timelog', :prop_key => 'remaining_estimate', :value => remaining_estimate >= 0 ? remaining_estimate : 0)
              end
              journal.save        
            end
          end                    
        end
        save_attachments(@issue, params[:attachments]) if params[:attachments]

        format.html
        format.xml { render :xml => @issue.to_xml(:include => {:attachments => {:only => [:id, :description, :filename], :methods => [:download_url]}, :author => {:only => [:id, :lastname, :firstname]},
          :assigned_to => {:only => [:id, :lastname, :firstname]}},
          :methods => [:spent_hours]),
        :status => :ok }
        format.json { render :json => @issue.to_json(:include => {:attachments => {:only => [:id, :description, :filename], :methods => [:download_url]}, :author => {:only => [:id, :lastname, :firstname]},
          :assigned_to => {:only => [:id, :lastname, :firstname]}},
          :methods => [:spent_hours]),
        :status => :ok }
      else
        format.html
        format.xml  { render :xml => @issue.errors, :status => :unprocessable_entity }
        format.json  { render :json => @issue.errors, :status => :unprocessable_entity }
      end
    end

  end

  #update existing ticket
  def update
    @issue = Issue.find(params[:id])
    hours = 0.0
    if params[:issue].has_key?(:log_time)
      hours = Float(params[:issue][:log_time])  
      params[:issue].delete(:log_time)      
    end
    respond_to do |format|
      if @issue.update_attributes(params[:issue])     
        if hours != 0.0
          @time_entry = TimeEntry.new(:project => @project, :issue => @issue, :user => @user, :spent_on => Date.today)
          time_entry_clone = @time_entry.clone
          @time_entry.activity_id = 8
          @time_entry.hours = hours
          TimeEntry.transaction do
            if @time_entry.save
              total_time_entry = TimeEntry.sum(:hours, :conditions => "issue_id = #{@issue.id}")
              journal = @time_entry.init_journal(@user)
              journal.details << JournalDetail.new(:property => 'timelog', :prop_key => 'hours', :old_value => (time_entry_clone.hours if time_entry_clone.hours != @time_entry.hours), :value => @time_entry.hours)
              journal.details << JournalDetail.new(:property => 'timelog', :prop_key => 'activity_id', :old_value => (time_entry_clone.activity_id if !time_entry_clone.activity_id.eql?(@time_entry.activity_id)), :value => @time_entry.activity_id)
              journal.details << JournalDetail.new(:property => 'timelog', :prop_key => 'spent_on', :old_value => (time_entry_clone.spent_on if !time_entry_clone.spent_on.eql?(@time_entry.spent_on)), :value => @time_entry.spent_on)
              if !@issue.estimated_hours.nil?
                remaining_estimate = @issue.estimated_hours - total_time_entry
                journal.details << JournalDetail.new(:property => 'timelog', :prop_key => 'remaining_estimate', :value => remaining_estimate >= 0 ? remaining_estimate : 0)
              end
              journal.save        
            end
          end                    
        end
        format.html
        format.xml { render :xml => @issue.to_xml(:include => {:attachments => {:only => [:id, :description, :filename], :methods => [:download_url]}, :author => {:only => [:id, :lastname, :firstname]},
          :assigned_to => {:only => [:id, :lastname, :firstname]}},
          :methods => [:spent_hours]),
        :status => :ok }
        format.json { render :json => @issue.to_json(:include => {:attachments => {:only => [:id, :description, :filename], :methods => [:download_url]}, :author => {:only => [:id, :lastname, :firstname]},
          :assigned_to => {:only => [:id, :lastname, :firstname]}},
          :methods => [:spent_hours]),
        :status => :ok }
      else
        format.html
        format.xml  { render :xml => @issue.errors, :status => :unprocessable_entity }
        format.json  { render :json => @issue.errors, :status => :unprocessable_entity }
      end
    end
  end

  def details
    @issue = @project.issues.find(params[:id])
    @attachments = @issue.attachments.collect {|a| {:description => a.description, :url => a.download_url}}

    if params[:last_comment]
      #@comments = @issue.journals.find(:all, :conditions => ["id > ?", params[:last_comment]])
    else
      #@comments = @issue.journals
    end

    respond_to do |format|
      format.html
      format.xml { render :xml => {'attachments' => @attachments } }
      format.json { render :json =>  {'attachments' => @attachments } }
    end
  end

  #close ticket
  def close
    @issue = @project.issues.find(params[:id])
    @issue.status = IssueStatus.find_by_name("Closed")
    Journal.create(:journalized_id => @issue.id, :journalized_type => "Issue", :user_id => @user.id, :notes => "Closed: #{params[:remarks] if params[:remarks]}")

    respond_to do |format|
    if @issue.save
      format.html
        format.xml { render :xml => @issue.to_xml(:include => {:attachments => {:only => [:id, :description, :filename], :methods => [:download_url]}, :author => {:only => [:id, :lastname, :firstname]},
          :assigned_to => {:only => [:id, :lastname, :firstname]}},
          :methods => [:spent_hours]),
        :status => :ok }
        format.json { render :json => @issue.to_json(:include => {:attachments => {:only => [:id, :description, :filename], :methods => [:download_url]}, :author => {:only => [:id, :lastname, :firstname]},
          :assigned_to => {:only => [:id, :lastname, :firstname]}},
          :methods => [:spent_hours]),
        :status => :ok }
    else
      format.xml { render :xml => @issue.errors, :status => :unprocessable_entity}
      format.json { render :json => @issue.errors, :status => :unprocessable_entity}
    end
    end
  end

  #reopen ticket
  def reopen
    @issue = @project.issues.find(params[:id])
    @issue.status = IssueStatus.find_by_name("Reopened")
    Journal.create(:journalized_id => @issue.id, :journalized_type => "Issue", :user_id => @user.id, :notes => "Reopened: #{params[:remarks] if params[:remarks]}")

    respond_to do |format|
    if @issue.save
      format.html
        format.xml { render :xml => @issue.to_xml(:include => {:attachments => {:only => [:id, :description, :filename], :methods => [:download_url]}, :author => {:only => [:id, :lastname, :firstname]},
          :assigned_to => {:only => [:id, :lastname, :firstname]}},
          :methods => [:spent_hours]),
        :status => :ok }
        format.json { render :json => @issue.to_json(:include => {:attachments => {:only => [:id, :description, :filename], :methods => [:download_url]}, :author => {:only => [:id, :lastname, :firstname]},
          :assigned_to => {:only => [:id, :lastname, :firstname]}},
          :methods => [:spent_hours]),
        :status => :ok }
    else
      format.xml { render :xml => @issue.errors, :status => :unprocessable_entity}
      format.json { render :json => @issue.errors, :status => :unprocessable_entity}
    end
    end
  end


  def comments
    @issue = @project.issues.find(params[:id])
    if params[:last_comment]
      @comments = @issue.journals.find(:all, :conditions => ["id > ? and notes <> ?", params[:last_comment], ""])
    else
      @comments = @issue.journals.find(:all, :conditions => ["notes <> ?", ""])
    end
    respond_to do |format|
      format.html
      format.xml { render :xml => @comments.to_xml(:include => {:user => {:only => [:id, :lastname, :firstname]}}   ) }
      format.json { render :json => @comments.to_json(:include => {:user => {:only => [:id, :lastname, :firstname]}}) }
    end
  end

  def add_comment
    @issue = @project.issues.find(params[:id])
    journal = @issue.journals.build(:user_id => @user.id, :notes => params[:remarks])
    #TODO: need to trigger mailer here

    respond_to do |format|
      if journal.save
        #update issue timestamp
        @issue.touch
        
        format.html
        format.xml { render :xml => journal.to_xml(:include => {:user => {:only => [:id, :lastname, :firstname]}} ), :status => :ok}
        format.json { render :json => journal.to_json(:include => {:user => {:only => [:id, :lastname, :firstname]}} ), :status => :ok }
      else
        format.html
        format.xml { render :xml => journal.errors , :status => :unprocessable_entity}
        format.json { render :json => journal.errors , :status => :unprocessable_entity }
      end
    end
  end

  protected

  def setup_controller
    @project = Project.find(params[:project_id]) if params[:project_id]
  end
end

