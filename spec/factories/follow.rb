FactoryBot.define do
  factory :follow do
    follower { create(:user) }
    followed { create(:user) }
    active { true }
  end
end
