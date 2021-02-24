class ChangedCommand
  prepend ActiveModel::Command

  class User
    include ActiveModel::Model

    attr_accessor :name, :sorted_tags, :unsorted_tags
  end

  command_subject :user

  attr_accessor :name, :sorted_tags, :unsorted_tags

  def call
    check_name
    check_sorted_tags
    check_unsorted_tags
    results
  end

  private

  def results
    @results ||= []
  end

  def check_name
    return unless changed?(:name)
    results << :name_changed
  end

  def check_sorted_tags
    return unless changed?(:sorted_tags, true)
    results << :sorted_tags_changed
  end

  def check_unsorted_tags
    return unless changed?(:unsorted_tags, false)
    results << :unsorted_tags_changed
  end
end
