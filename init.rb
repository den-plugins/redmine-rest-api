require 'redmine'

RAILS_DEFAULT_LOGGER.info 'Starting Redmine REST Api plugin'

Redmine::Plugin.register :redmine_rest_api do
  name 'Redmine REST Api plugin'
  author 'Allan Melvin T. Sembrano - melvinsembrano@gmail.com'
  description 'Plugin for exposing Redmine RESTful apis'
  version '0.0.2'
end

ActionController::Base.send :include, ApplicationMethods
begin
ActiveRecord::Base.send :include, ModelMethods::Base #unless Issue.new.respond_to?(:touch)
rescue

end
Attachment.send :include, ModelMethods::Attachment

