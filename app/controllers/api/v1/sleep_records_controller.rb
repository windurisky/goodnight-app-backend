module Api
  module V1
    class SleepRecordsController < BaseController
      before_action :authenticate_user!

      def clock_in
        sleep_record = Sleep::ClockInService.call(user: current_user)

        render json: {
          message: "Clock in successful",
          sleep_record_id: sleep_record.id
        }, status: :created
      end
    end
  end
end
