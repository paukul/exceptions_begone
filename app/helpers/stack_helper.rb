module StackHelper

  def filter_options
    {
      "all"      => "show all",
      "default"  => "show all except done",
      "open"     => "show open",
      "progress" => "show in progress",
      "done"     => "show done",
      "include"  => "show excluded"
    }
  end

  def pagination_options
    [50, 100, 200]
  end
  
  def number_of_exceptions_for_usertimeslice(stack)
    stack.last_occurred_at >= session[:exceptions_since] ? stack.notifications.where(:created_at.gt => session[:exceptions_since].utc).count : 0
  end

end