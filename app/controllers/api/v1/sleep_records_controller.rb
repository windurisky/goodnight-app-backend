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
    end
  end
end
