class Notification < ActiveRecord::Base
  self.inheritance_column = :_unused
  belongs_to :notified_user, class_name: User
  belongs_to :originating_user, class_name: User
  belongs_to :event
  belongs_to :subscription

  enum type: [:subscribed_event, :mention, :site_update, :message]
end