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
    notification.stack.example ||= parameters[:identifier]

    if notification.stack.status == "done"
      notification.stack.reset_status!
    end

    notification
  end

  private 

  def self.replace_numbers(identifier)
    fingerprint = identifier.gsub(/(@[\S]+=)(\S+)(,)?/) {"#{$1}[IVAR]#{$3}"}
    fingerprint = fingerprint.gsub(/(#<[^:]|[\S:{2}]+:)(\dx[\da-f]+)(.*)$/) {|s| $1 + '[OBJECT_ID]' + $3}
    fingerprint = fingerprint.gsub(/(\d)+/, '[NUMBER]')
    fingerprint
  end
end
