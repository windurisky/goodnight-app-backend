module Sleeps
  class GetFollowingsSleepRecordsService < ApplicationService
    def initialize(user:, page: 1, per_page: 10)
      @user = user
      @page = page
      @per_page = per_page
    end

    def call
      SleepRecord
        .clocked_out
        .last_week
        # use subquery to avoid passing large array to where clause
        .where(user_id: User.where(id: @user.followings.select(:id)))
        .includes(:user)
        .order(duration: :desc)
        .page(@page)
        .per(@per_page)
        .without_count
    end
  end
end
