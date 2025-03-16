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
        start_index = (params[:start_index] || 0).to_i
        per_page = (params[:per_page] || 10).to_i

        sleep_records, last_index = Sleeps::GetPrecomputedTimelineService.call(
          user: current_user,
          start_index: start_index,
          per_page: per_page
        )

        pagination = {
          start_index: start_index,
          per_page: per_page,
          last_index: last_index
        }

        render json: { data: sleep_records, pagination: pagination }, status: :ok
      end
    end
  end
end
