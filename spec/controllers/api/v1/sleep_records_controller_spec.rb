require "rails_helper"

RSpec.describe Api::V1::SleepRecordsController, type: :controller do
  let(:user) { create(:user) }
  let(:jwt_secret) { "test_secret" }
  let(:token) { JWT.encode({ username: user.username }, jwt_secret) }

  before do
    stub_const("ENV", ENV.to_hash.merge("JWT_SECRET_KEY" => jwt_secret))
    request.headers["Authorization"] = "Bearer #{token}"
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "#clock_in" do
    context "when successful" do
      it "calls the clock in service and returns success message" do
        sleep_record = build(:sleep_record, user: user, id: "test-uuid")

        expect(Sleeps::ClockInService).to receive(:call).with(
          user: user
        ).and_return(sleep_record)

        post :clock_in

        expect(response).to have_http_status(:created)
        json_response = response.parsed_body
        expect(json_response["message"]).to eq("Clock in successful")
        expect(json_response["sleep_record_id"]).to eq("test-uuid")
      end
    end

    context "when already clocked in" do
      it "returns a bad request error" do
        expect(Sleeps::ClockInService).to receive(:call).with(
          user: user
        ).and_raise(SleepError::AlreadyClockedIn)

        post :clock_in

        expect(response).to have_http_status(:bad_request)
        json_response = response.parsed_body
        expect(json_response["error"]["code"]).to eq("already_clocked_in")
        expect(json_response["error"]["message"]).to include("already clocked in")
      end
    end

    context "when not authenticated" do
      before do
        request.headers["Authorization"] = nil
      end

      it "returns an unauthorized error" do
        post :clock_in

        expect(response).to have_http_status(:unauthorized)
        json_response = response.parsed_body
        expect(json_response["error"]["code"]).to eq("unauthorized")
      end
    end
  end

  describe "#clock_out" do
    context "when successful" do
      it "calls the clock out service and returns success message" do
        sleep_record = build(:sleep_record, user: user, duration: 28_800, state: "clocked_out")

        expect(Sleeps::ClockOutService).to receive(:call).with(
          user: user
        ).and_return(sleep_record)

        post :clock_out

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body
        expect(json_response["message"]).to eq("Clock out successful")
        expect(json_response["duration"]).to eq(28_800)
      end
    end

    context "when not clocked in" do
      it "returns a bad request error" do
        expect(Sleeps::ClockOutService).to receive(:call).with(
          user: user
        ).and_raise(SleepError::NotClockedIn.new)

        post :clock_out

        expect(response).to have_http_status(:bad_request)
        json_response = response.parsed_body
        expect(json_response["error"]["code"]).to eq("not_clocked_in")
        expect(json_response["error"]["message"]).to eq("You are not clocked in, must clock in first")
      end
    end

    context "when not authenticated" do
      before do
        request.headers["Authorization"] = nil
      end

      it "returns an unauthorized error" do
        post :clock_out

        expect(response).to have_http_status(:unauthorized)
        json_response = response.parsed_body
        expect(json_response["error"]["code"]).to eq("unauthorized")
      end
    end
  end

  describe "#followings" do
    let(:followed_user) { create(:user, username: "followed_user", name: "Followed User") }
    let(:sleep_record) do
      create(:sleep_record,
             user: followed_user,
             state: "clocked_out",
             clocked_in_at: 1.day.ago,
             clocked_out_at: 1.day.ago + 8.hours,
             duration: 28_800)
    end
    let(:paginated_records) { Kaminari.paginate_array([sleep_record]).page(1).per(10) }

    context "when successful with default pagination" do
      it "calls the service with default pagination parameters" do
        expect(Sleeps::GetFollowingsSleepRecordsService).to receive(:call).with(
          user: user,
          page: 1,
          per_page: 10
        ).and_return(paginated_records)

        # Mock the last_page? method
        allow(paginated_records).to receive(:last_page?).and_return(true)

        get :followings

        expect(response).to have_http_status(:ok)
      end

      it "returns formatted sleep records with pagination info" do
        expect(Sleeps::GetFollowingsSleepRecordsService).to receive(:call)
          .with(user: user, page: 1, per_page: 10)
          .and_return(paginated_records)

        # Mock the last_page? method
        allow(paginated_records).to receive(:last_page?).and_return(true)

        get :followings

        json_response = response.parsed_body

        # Check structure
        expect(json_response).to have_key("data")
        expect(json_response).to have_key("pagination")

        # Check pagination info
        expect(json_response["pagination"]).to include(
          "page" => 1,
          "per_page" => 10,
          "is_last_page" => true
        )

        # Check data format
        expect(json_response["data"].first).to include(
          "id" => sleep_record.id,
          "duration" => 28_800,
          "clocked_in_at" => sleep_record.clocked_in_at.iso8601,
          "clocked_out_at" => sleep_record.clocked_out_at.iso8601
        )

        # Check user info
        expect(json_response["data"].first["user"]).to include(
          "id" => followed_user.id,
          "username" => "followed_user",
          "name" => "Followed User"
        )
      end
    end

    context "when custom pagination parameters are provided" do
      it "passes the custom pagination parameters to the service" do
        expect(Sleeps::GetFollowingsSleepRecordsService).to receive(:call).with(
          user: user,
          page: 2,
          per_page: 5
        ).and_return(paginated_records)

        # Mock the last_page? method
        allow(paginated_records).to receive(:last_page?).and_return(true)

        get :followings, params: { page: 2, per_page: 5 }

        expect(response).to have_http_status(:ok)

        json_response = response.parsed_body
        expect(json_response["pagination"]["page"]).to eq(2)
        expect(json_response["pagination"]["per_page"]).to eq(5)
      end
    end

    context "when the result is an empty array" do
      it "returns empty data with is_last_page true" do
        expect(Sleeps::GetFollowingsSleepRecordsService).to receive(:call)
          .with(user: user, page: 1, per_page: 10)
          .and_return([])

        get :followings

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body
        expect(json_response["data"]).to be_empty
        expect(json_response["pagination"]["is_last_page"]).to be true
      end
    end

    context "when not on the last page" do
      it "returns is_last_page as false" do
        expect(Sleeps::GetFollowingsSleepRecordsService).to receive(:call)
          .with(user: user, page: 1, per_page: 10)
          .and_return(paginated_records)

        allow(paginated_records).to receive(:last_page?).and_return(false)

        get :followings

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body
        expect(json_response["pagination"]["is_last_page"]).to be false
      end
    end

    context "when not authenticated" do
      before do
        request.headers["Authorization"] = nil
      end

      it "returns an unauthorized error" do
        get :followings

        expect(response).to have_http_status(:unauthorized)
        json_response = response.parsed_body
        expect(json_response["error"]["code"]).to eq("unauthorized")
      end
    end
  end
end
