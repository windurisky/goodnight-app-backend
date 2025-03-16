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

  describe "#followings" do
    let(:sleep_records) { [{ "id" => "test-uuid", "duration" => 28_800 }] }
    let(:pagination) { { "start_index" => 0, "per_page" => 10, "last_index" => 10 } }

    context "when successful with default pagination" do
      it "calls the correct service and returns formatted sleep records" do
        expect(Sleeps::GetPrecomputedTimelineService).to receive(:call).with(
          user: user,
          start_index: 0,
          per_page: 10
        ).and_return([sleep_records, 10])

        get :followings

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response["data"]).to eq(sleep_records)
        expect(json_response["pagination"]).to eq(pagination)
      end
    end

    context "when an empty result is returned" do
      it "returns an empty array with correct pagination" do
        expect(Sleeps::GetPrecomputedTimelineService).to receive(:call).with(
          user: user,
          start_index: 0,
          per_page: 10
        ).and_return([[], 0])

        get :followings

        json_response = response.parsed_body

        expect(json_response["data"]).to eq([])
        expect(json_response["pagination"]["last_index"]).to eq(0)
      end
    end

    context "when not authenticated" do
      before { request.headers["Authorization"] = nil }

      it "returns an unauthorized error" do
        get :followings

        expect(response).to have_http_status(:unauthorized)
        json_response = response.parsed_body
        expect(json_response["error"]["code"]).to eq("unauthorized")
      end
    end
  end
end
