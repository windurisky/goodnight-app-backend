class User < ApplicationRecord
  has_secure_password

  has_many :following_relations, class_name: "Follow", foreign_key: "follower_id", inverse_of: :follower
  has_many :follower_relations, class_name: "Follow", foreign_key: "followed_id", inverse_of: :followed

  has_many :followings, -> { where(follows: { active: true }) }, through: :following_relations, source: :followed
  has_many :followers, -> { where(follows: { active: true }) }, through: :follower_relations, source: :follower

  validates :username, presence: true, uniqueness: true
  validates :password, presence: true, on: :create

  before_create :generate_uuid_v7
end
