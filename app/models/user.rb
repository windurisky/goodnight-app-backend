class User < ApplicationRecord
  has_secure_password

  has_many :following_relations, class_name: "Follow", foreign_key: "follower_id", inverse_of: :follower
  has_many :follower_relations, class_name: "Follow", foreign_key: "followed_id", inverse_of: :followed
  has_many :followings, -> { where(follows: { active: true }) }, through: :following_relations, source: :followed
  has_many :followers, -> { where(follows: { active: true }) }, through: :follower_relations, source: :follower

  has_many :sleep_records

  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :password, presence: true, on: :create

  before_create :generate_uuid_v7

  def following?(user)
    following_relations.find_by(followed_id: user.id)&.active?
  end

  def follower_of?(user)
    follower_relations.find_by(follower_id: user.id)&.active?
  end
end
