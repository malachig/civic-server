class Event < ActiveRecord::Base
  belongs_to :subject, ->() { unscope(where: :deleted) }, polymorphic: true
  belongs_to :originating_user, foreign_key: :originating_user_id, class_name: 'User'
  validates :action, :originating_user_id, :subject, presence: true
  validate :subject_is_subscribable

  serialize :state_params, JSON

  after_create :queue_feed_updates
  before_save :store_state_params

  private
  def subject_is_subscribable
    unless subject.is_a?(Subscribable)
      errors.add(:subject, 'Subject must be a Subscribable object')
    end
  end

  def store_state_params
    self.state_params = self.state_params.merge(subject.state_params)
  end

  def queue_feed_updates
    NotifySubscribers.perform_later(self)
  end
end
