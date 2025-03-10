module Socials
  class FollowService < ApplicationService
    def initialize(user:, target_user_id:)
      @user = user
      @target_user_id = target_user_id
    end

    def call
      validate!

      if existing_follow
        existing_follow.update!(active: true)
        existing_follow
      else
        Follow.create!(
          follower: @user,
          followed: target_user,
          active: true
        )
      end
    end

    private

    def target_user
      @target_user ||= User.find_by(id: @target_user_id)
    end

    def existing_follow
      @existing_follow = Follow.find_by(
        follower_id: @user.id,
        followed_id: target_user.id
      )
    end

    def validate!
      raise UserError::NotFound if target_user.blank?
      raise FollowError::AlreadyFollowed if existing_follow&.active?
    end
  end
end
