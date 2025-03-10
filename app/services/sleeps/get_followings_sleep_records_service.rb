module Sleeps
  class GetFollowingsSleepRecordsService < ApplicationService
    def initialize(user:, page: 1, per_page: 10)
      @user = user
      @page = page
      @per_page = per_page
    end

    def call
      following_ids = @user.followings.pluck(:id)

      return [] if following_ids.empty?

      SleepRecord
        .clocked_out
        .last_week
        .where(user_id: following_ids)
        .includes(:user)
        .order(duration: :desc)
        .page(@page)
        .per(@per_page)
        .without_count
    end
  end
end
