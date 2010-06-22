class Stack 
  include Mongoid::Document
  include Mongoid::Timestamps

  cattr_reader :per_page
  @@per_page = 10

  field :identifier
  field :status, :type => Integer
  field :notifications_count, :type => Integer, :default => 0
  field :category
  field :email_sent, :type => Integer, :default => 0
  field :threshold_warning_sent, :type => Integer, :default => 0
  field :last_occurred_at, :type => DateTime
  field :username, :type => String
  
  belongs_to_related :project
  has_many_related :notifications, :dependent => :destroy
    
  # named_scope :for_email_notifications, :conditions => {:email_sent => false}
  # named_scope :exceeding_warning_threshold, lambda { |threshold| {:conditions => ["notifications_count > ?", threshold]} }
  # named_scope :warning_not_sent, :conditions => ["threshold_warning_sent != ?", true]

  @@status_to_integer = {"open" => 0, "in progress" => 1, "done" => 2}
  @@integer_to_status = @@status_to_integer.invert
   
  before_create do |record|
    record.status = @@integer_to_status[0]
    record.last_occurred_at = Time.now unless record.last_occurred_at
  end

  before_update do |record|
    record.last_occurred_at = Time.now
  end
    
  class << self
    def conditions_for_exclusions(exclusions, matching_mode)
      exclusions_patterns = exclusions.active.map(&:pattern)
      
      regex_command = matching_mode == :exclude ? "NOT REGEXP" : "REGEXP"
      
      if exclusions_patterns.present?
        sql_pattern = "(#{exclusions_patterns.join('|')})"
        { :conditions => "identifier #{regex_command} '#{sql_pattern}'" }
      else
        {}
      end
    end
  
    def condition_for_filter(filter)
      case filter
      when "all"
        {}
      when "done"
        {:status => 2}
      when "incoming"
        {:status => 0}
      when "in_progress"
        {:status => 1}
      else
        {:status.nin => [2]}
      end
    end
    
    def send_notifications_to_users
      stacks = stacks_awaiting_sending
      logger.info("[EMAIL] sending notification about following stacks: #{stacks.map(&:id)}")
      stacks.each do |stack|
        NotificationsMailer.deliver_notification(stack)
        stack.email_sent = 1
        stack.threshold_warning_sent = 1 if stack.warning_threshold_exceeded?
        stack.save!
      end
    end

    def stacks_awaiting_sending
      awaiting_stacks = []
      Project.find(:all).each do |project|
        exclusion_patterns = project.exclusions.where(:enabled => true).map(&:pattern)
        if exclusion_patterns.present?
          awaiting_stacks += project.stacks.where({:email_sent => 0, :identifier.ne => /#{exclusion_patterns.join('|')}/})
          awaiting_stacks += project.stacks.where(:identifier.ne => /#{exclusion_patterns.join('|')}/, :threshold_warning_sent => 0, :notifications_count.gt => project.warning_threshold)
        else
          awaiting_stacks += project.stacks.where(:email_sent => 0)
          awaiting_stacks += project.stacks.where(:threshold_warning_sent => 0, :notifications_count.gt => project.warning_threshold)
        end
      end
      remove_routing_errors(awaiting_stacks)
    end
    
    def remove_routing_errors(stacks)
      stacks.reject { |stack| stack.identifier =~ /\(ActionController::RoutingError\)/ && !stack.notifications.first.payload.include?("HTTP_REFERER") }
    end
    
    def find_or_create(project, category, identifier)
      find_or_create_by_project_id_and_category_and_identifier(project.id, category, identifier)
    end

    def logger
      @@logger ||= Rails.logger
    end
  end
  
  def reset_status!
    self.status = @@integer_to_status[0]
    self.email_sent = 0
    self.threshold_warning_sent = 0
    self.save!
  end

  def status
    @@integer_to_status.fetch(super, @@integer_to_status[0])
  end
  
  def status=(s)
    self[:status] = s.is_a?(Integer) ? s : @@status_to_integer[s]
  end
  
  def cycle_status
    actual_integer_status = @@status_to_integer[status]
    @@integer_to_status.fetch(actual_integer_status + 1, @@integer_to_status[0])
  end
  
  def can_change_status?(username)
    if status == @@integer_to_status[0]
      true
    else
      self.username == username
    end
  end
  
  def warning_threshold_exceeded?
    notifications_count > project.warning_threshold
  end
end
