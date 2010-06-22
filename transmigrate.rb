require 'rubygems'
require 'bundler'
Bundler.setup

require 'mongo'
c = Mongo::Connection.new
d = c["notification-center-production"]
projects = d["projects"]
stacks = d["stacks"]
notifications = d["notifications"]

projects.find.each do |project|
  old_project_id = project["_id"]
  new_project_id = old_project_id.to_s

  puts "Updating #{project['name']}"
  new_project = project.dup
  new_project["_id"] = new_project_id
  puts "Updating Stacks"
  stacks.find("project_id" => old_project_id).each do |stack|
    $stdout.print('.')
    $stdout.flush
    
    old_stack_id = stack["_id"]
    new_stack_id = old_stack_id.to_s

    new_stack = stack.dup
    new_stack["_id"] = new_stack_id
    new_stack["project_id"] = new_project_id
    
    notifications.find("stack_id" => old_stack_id).each do |notification|
      old_notification_id = notification["_id"]
      new_notification_id = old_notification_id.to_s

      new_notification = notification.dup
      new_notification["_id"] = new_notification_id
      new_notification["stack_id"] = new_stack_id
      
      notifications.insert(new_notification)
      notifications.remove(notification)
    end
    
    stacks.insert(new_stack)
    stacks.remove(stack)
  end
  puts
  puts "Deleting old #{project['name']}"
  projects.insert(new_project)
  projects.remove(project)
end