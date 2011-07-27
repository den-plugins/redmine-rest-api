  connect '/projects/:project_id/issues/:issue_id/attachments/:id/file', :controller => 'apis/attachments', :action => 'show'

#  connect 'apis/projects/:project_id/issues/:issue_id/attachments '
  namespace(:apis) do |apis|
    apis.resources :users, :collection => {:authenticate => :post}
    apis.resources :projects, :member => {:maintenances => :get } do |projects|
      projects.resources :issues, :member => {:attach_file => :post, :comments => :get,
      :details => :get, :add_comment => :post, :close => :post, :reopen => :post} do |issues|
        issues.resources :attachments
      end
    end
    apis.resources :activities
    apis.resources :attachments, :collection => {:create => :post, :destroy => :delete}
  end


