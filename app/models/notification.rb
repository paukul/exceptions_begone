class Notification 
  include Mongoid::Document
  include Mongoid::Timestamps

  field :identifier, :type => String
  field :payload, :type => String
  field :status, :type => String
  index :created_at
  index :status
  index :stack_id

  belongs_to_related :stack #, :counter_cache => true, :touch => :last_occured_at

  after_create do |record|
    record.stack.notifications_count += 1
    record.stack.save
  end

  def self.build(project, parameters)
    identifier, payload = parameters[:identifier], parameters[:payload].to_json

    notification = self.new(:payload => payload, :identifier => identifier)
    notification.stack = Stack.find_or_create_by(:project_id => project.id, :category => parameters[:category], :identifier => replace_numbers(identifier))

    if notification.stack.status == "done"
      notification.stack.reset_status!
    end

    notification
  end

  private 

  def self.replace_numbers(identifier)
    identifier.gsub(/(\d)+/, '%s')
  end
end
