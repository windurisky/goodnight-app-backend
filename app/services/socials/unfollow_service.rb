module Socials
  class UnfollowService < ApplicationService
    def initialize(user:, target_user_id:)
      @user = user
      @target_user_id = target_user_id
    end

    def call
      validate!

      existing_follow.update!(active: false)
      existing_follow
    end

    private

    def target_user
      @target_user ||= User.find_by(id: @target_user_id)
    end

    def existing_follow
      @existing_follow ||= Follow.find_by(
        follower_id: @user.id,
        followed_id: target_user.id
      )
    end

    def validate!
      raise UserError::NotFound if target_user.blank?
      raise FollowError::AlreadyUnfollowed if existing_follow.blank?
      raise FollowError::AlreadyUnfollowed unless existing_follow.active?
    end
  end
end
