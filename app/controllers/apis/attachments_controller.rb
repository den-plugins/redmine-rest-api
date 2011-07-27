class Apis::AttachmentsController < ApplicationController
  skip_before_filter :check_if_login_required
  #before_filter :authenticate, :only => [:create]
  before_filter :setup_controller

  #get attachment
  def show
    @attachment = Attachment.find(params[:id])

    # codes from original controller codes
    if Attachment.uses_s3?
      send_s3_file @attachment, :filename => filename_for_content_disposition(@attachment.filename),
                                    :type => @attachment.content_type,
                                    :disposition => (@attachment.image? ? 'inline' : 'attachment')
    else
      send_file @attachment.diskfile, :filename => filename_for_content_disposition(@attachment.filename),
                                    :type => @attachment.content_type,
                                    :disposition => (@attachment.image? ? 'inline' : 'attachment')
    end
  end

  #attach new file
  def create
    att = params
    respond_to do |format|

      @user = User.try_to_login(att[:username], att[:password])
      if @user
        @attachment = Attachment.create(
            :container => @issue,
            :file => att[:file],
            :description => att['description'].to_s.strip,
            :author => @user)

        format.html
        format.xml { render :xml => @attachment.to_xml(:only => [:id, :description, :filename], :methods => [:download_url]), :status => :ok}
        format.json { render :json => @attachment.to_json(:only => [:id, :description, :filename], :methods => [:download_url]), :status => :ok}
      else
        render :xml => "user authentication required.", :status => '401'
        render :json => "user authentication required.", :status => '401'
      end
    end

  end

  def destroy
    @attachment = Attachment.find(params[:id])
    respond_to do |format|
      if @attachment.destroy
        format.html
        format.xml { render :xml => true, :status => :ok}
        format.json { render :json => true, :status => :ok }
      else
        format.xml { render :xml => @attachment.errors, :status => :unprocessable_entity }
        format.json { render :json => @attachment.errors, :status => :unprocessable_entity }
      end
    end
  end

  protected

  def save_attachments(obj, attachments)
    att = []
    attachments.each do |attachment|
      att << Attachment.create(
        :container => obj,
        :file => attachment[:file],
        :description => attachment['description'].to_s.strip,
        :author => @user)
    end
    return att
  end


  def setup_controller
    @project = Project.find(params[:project_id])
    @issue = @project.issues.find(params[:issue_id])
  end
end

