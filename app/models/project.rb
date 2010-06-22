class Project
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name
  field :description
  field :warning_threshold, :type => Integer, :default => 10

  has_many_related :stacks
  has_many_related :exclusions

  def find_stacks(search_query, filter, options = {})
    exclusion_patterns = exclusions.where(:enabled => true).map(&:pattern)
    if search_query
      stacks.where({:identifier => /#{search_query}/}.merge(options))
    elsif filter.present?
      if exclusion_patterns.present?
        stacks.where({:identifier.ne => /#{exclusion_patterns.join('|')}/}.merge(Stack.condition_for_filter(filter)).merge(options))
      else
        stacks.where(Stack.condition_for_filter(filter).merge(options))
      end
    else
      stacks.where(options)
    end
  end
end
