class Follow < ApplicationRecord
  before_create :generate_uuid_v7

  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"

  validate :cannot_follow_yourself

  scope :active, -> { where(active: true) }

  private

  def cannot_follow_yourself
    return unless follower_id == followed_id

    errors.add(:followed_id, "You cannot follow yourself")
  end
end
