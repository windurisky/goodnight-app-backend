module Api
  module V1
    class SocialsController < Api::V1::BaseController
      before_action :authenticate_user!

      def follow
        ::Socials::FollowService.call(
          user: current_user,
          target_user_id: params[:user_id]
        )

        render json: { message: "Successfully followed user" }, status: :created
      end

      def unfollow
        ::Socials::UnfollowService.call(
          user: current_user,
          target_user_id: params[:user_id]
        )

        render json: { message: "Successfully unfollowed user" }, status: :ok
      end

      # TODO: GET - list of followers logic (low prio)
      def followers; end
      # TODO: GET - list of followings logic (low prio)
      def followings; end
    end
  end
end
