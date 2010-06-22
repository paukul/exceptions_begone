class ApplicationController < ActionController::Base
  layout 'application'
  helper :all # include all helpers, all the time
  
  helper_method :current_user
  
  private
    
  def current_user
    cookies[:current_user]
  end
  
  def load_project
    project_id = params[:project_id] ? params[:project_id] : params[:id]

    @project = Project.find(project_id)

  end
  
end
