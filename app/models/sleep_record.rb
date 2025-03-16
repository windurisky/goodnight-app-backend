class SleepRecord < ApplicationRecord
  include AASM

  before_create :generate_uuid_v7

  belongs_to :user

  validates :clocked_in_at, presence: true
  validate :valid_clock_out_time, if: -> { clocked_out_at.present? }

  scope :last_week, -> { where(clocked_in_at: 1.week.ago.beginning_of_day..) }

  aasm column: :state, requires_lock: true do
    state :clocked_in, initial: true
    state :clocked_out

    event :clock_out, after_commit: :post_clock_out_events do
      transitions from: :clocked_in, to: :clocked_out do
        after do
          self.clocked_out_at = Time.current
          self.duration = (clocked_out_at - clocked_in_at).to_i
        end
      end
    end
  end

  def visibility_expiry_time
    clocked_in_at + 1.week
  end

  def visible?
    Time.current < visibility_expiry_time
  end

  private

  def valid_clock_out_time
    errors.add(:clocked_out_at, "must be after the clock in time") if clocked_out_at <= clocked_in_at
  end

  def post_clock_out_events
    UpdateSelfRecordJob.perform_later(id)
    FanOutSleepRecordToFollowersJob.perform_later(id)
  end
end
