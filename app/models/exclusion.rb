class Exclusion
  include Mongoid::Document
  include Mongoid::Timestamps  

  field :name, :type => String
  field :enabled, :type => Boolean, :default => false
  field :pattern, :type => String

  belongs_to_related :project
  
  validates_presence_of :name
  validates_presence_of :pattern
  
  # named_scope :active, :conditions => ["enabled = ?", true]
  
end
