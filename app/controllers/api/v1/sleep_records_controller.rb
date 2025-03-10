module Api
  module V1
    class SleepRecordsController < BaseController
      before_action :authenticate_user!

      def clock_in
        sleep_record = Sleeps::ClockInService.call(user: current_user)

        render json: {
          message: "Clock in successful",
          sleep_record_id: sleep_record.id
        }, status: :created
      end

      def clock_out
        sleep_record = Sleeps::ClockOutService.call(user: current_user)

        render json: {
          message: "Clock out successful",
          duration: sleep_record.duration
        }, status: :ok
      end

      def followings
        page = params[:page] || 1
        per_page = params[:per_page] || 10

        sleep_records = Sleeps::GetFollowingsSleepRecordsService.call(
          user: current_user,
          page: page,
          per_page: per_page
        )

        pagination = {
          page: page,
          per_page: per_page,
          is_last_page: sleep_records.last_page? || sleep_records.empty?
        }

        render json: { data: format_sleep_record(sleep_records), pagination: pagination }, status: :ok
      end

      private

      # TODO: Start using serializer if there are other endpoints that need to be formatted
      def format_sleep_record(sleep_records)
        sleep_records.map do |sleep_record|
          {
            id: sleep_record.id,
            clocked_in_at: sleep_record.clocked_in_at.iso8601,
            clocked_out_at: sleep_record.clocked_out_at.iso8601,
            duration: sleep_record.duration,
            humanized_duration: ActiveSupport::Duration.build(sleep_record.duration).inspect,
            user: {
              id: sleep_record.user.id,
              username: sleep_record.user.username,
              name: sleep_record.user.name
            }
          }
        end
      end
    end
  end
end
