require "rails_helper"

RSpec.describe SleepRecord, type: :model do
  before do
    travel_to Time.zone.local(2025, 2, 1, 10, 30)
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:clocked_in_at) }

    context "when clocked_out_at is present" do
      let(:user) { create(:user) }
      let(:clocked_in_time) { 8.hours.ago }

      context "when clocked_out_at after clocked_in_at" do
        it "is valid" do
          sleep_record = described_class.new(
            user: user,
            clocked_in_at: clocked_in_time,
            clocked_out_at: clocked_in_time + 1.hour
          )
          expect(sleep_record).to be_valid
        end
      end

      context "when clocked_out_at equal to clocked_in_at" do
        it "is invalid" do
          sleep_record = described_class.new(
            user: user,
            clocked_in_at: clocked_in_time,
            clocked_out_at: clocked_in_time
          )
          expect(sleep_record).not_to be_valid
          expect(sleep_record.errors[:clocked_out_at]).to include("must be after the clock in time")
        end
      end

      context "when clocked_out_at before clocked_in_at" do
        it "is invalid" do
          sleep_record = described_class.new(
            user: user,
            clocked_in_at: clocked_in_time,
            clocked_out_at: clocked_in_time - 1.hour
          )
          expect(sleep_record).not_to be_valid
          expect(sleep_record.errors[:clocked_out_at]).to include("must be after the clock in time")
        end
      end
    end
  end

  describe "scopes" do
    let(:user) { create(:user) }

    describe "last_week" do
      before do
        # Create records at different times
        create(:sleep_record, user: user, clocked_in_at: 2.days.ago)
        create(:sleep_record, user: user, clocked_in_at: 8.days.ago)
        create(:sleep_record, user: user, clocked_in_at: 10.days.ago)
      end

      it "returns only records from the last week" do
        expect(described_class.last_week.count).to eq(1)
        expect(described_class.last_week.first.clocked_in_at).to be > 7.days.ago
      end
    end
  end

  describe "state machine" do
    let(:user) { create(:user) }
    let(:sleep_record) { create(:sleep_record, user: user, clocked_in_at: 8.hours.ago) }

    describe "#clock_out" do
      it "transitions from clocked_in to clocked_out" do
        expect(sleep_record.state).to eq("clocked_in")
        expect(sleep_record.clocked_out_at).to be_nil
        expect(sleep_record.duration).to eq(0)

        sleep_record.clock_out!

        expect(sleep_record.state).to eq("clocked_out")
        expect(sleep_record.clocked_out_at).to be_present
        expect(sleep_record.duration).to be > 0
      end

      it "calculates duration in seconds" do
        clocked_in_time = 4.hours.ago
        record = create(:sleep_record, user: user, clocked_in_at: clocked_in_time)

        record.clock_out!

        # Should be approximately 4 hours in seconds (14400), allow 5 second margin for test execution time
        expect(record.duration).to be_within(5).of(4.hours.to_i)
      end

      it "doesn't allow transition back to clocked_in" do
        sleep_record.clock_out!

        expect do
          sleep_record.clock_out!
        end.to raise_error(AASM::InvalidTransition)
      end
    end
  end

  describe "uuid generation" do
    let(:user) { create(:user) }

    it "generates a UUID v7 on creation" do
      sleep_record = create(:sleep_record, user: user)
      expect(sleep_record.id).to be_present
      expect(sleep_record.id).to be_a_uuid(version: 7)
    end
  end
end
