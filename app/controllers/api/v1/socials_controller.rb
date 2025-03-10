module Api
  module V1
    class SocialsController < Api::V1::BaseController
      def follow
        ::Socials::FollowService.call(
          user: current_user,
          target_user_id: follow_params[:user_id]
        )

        render json: { message: "Successfully followed" }, status: :created
      end

      def unfollow
        ::Socials::UnfollowService.call(
          user: current_user,
          target_user_id: unfollow_params[:user_id]
        )

        render json: { message: "Successfully unfollowed" }, status: :ok
      end

      # TODO: GET - list of followers logic (low prio)
      def followers; end
      # TODO: GET - list of followings logic (low prio)
      def followings; end

      private

      def follow_params
        params.require(:follow).permit(:user_id)
      end

      def unfollow_params
        params.require(:unfollow).permit(:user_id)
      end
    end
  end
end
