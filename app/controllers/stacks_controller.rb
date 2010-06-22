class StacksController < ApplicationController
  
  before_filter :load_project
  
  @@order_possiblities = { 
    "status"      => [:status,              :asc],
    "category"    => [:category,            :asc],
    "identifier"  => [:identifier,          :asc],
    "updated_at"  => [:updated_at,          :desc],
    "created_at"  => [:created_at,          :desc],
    "count"       => [:notifications_count, :desc]
  }
  
  def index
    session[:exceptions_since] = params[:exceptions_since].blank? ? session[:exceptions_since] || 1.day.ago : Time.at(params[:exceptions_since].to_i)
    order_options    = @@order_possiblities.fetch(params[:order], [:updated_at, :desc])
    session[:filter] = params[:filter] ? params[:filter] : session[:filter] || "default"
    session[:per_page] = (params[:per_page] || session[:per_page] || 50).to_i
    matching_mode = params[:filter] == "include" ? :include : :exclude

    pagination_opts = {:per_page => session[:per_page], :page => params[:page] || 1}
    @stacks = @project.find_stacks(params[:search], session[:filter]).order_by(order_options).paginate(pagination_opts)
    
    aggregation = Notification.only(:stack_id).where(:created_at.gt => session[:exceptions_since].utc).in(@stacks.map(&:id)).aggregate
    @recents = aggregation.inject({}) {|ret, obj| ret[obj["stack_id"]] = obj["count"]; ret}
  end
  
  def show
    @stack = Stack.find(params[:id])
    
    @notifications = @stack.notifications.paginate(:per_page => 1, :page => params[:page])
    
    @notification = @notifications.first
    
    @sections = ActiveSupport::JSON.decode(@notification.payload)
    @sections["Info"] = {"Occured at" => @notification.created_at }
    @backtrace = @sections.delete("backtrace")
    @backtrace = @backtrace.join("<br/>") if @backtrace.present?
  end
  
  def update
    @stack = @project.stacks.find(params[:id])
    @stack.update_attributes(params[:stack])
    if @stack.save
      flash[:notice] = "Notification succefully updated"
      respond_to do |format|
        format.js
        format.html { redirect_to project_stacks_url(@project) }
      end
    else
      redirect_to project_stacks_url(@project)
    end
  end
  
  def destroy
    @stack = Stack.find(params[:id])
    Stack.destroy_all(:identifier => @stack.identifier)
    redirect_to project_stacks_url(@project)
  end
end
