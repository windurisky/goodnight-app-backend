FactoryBot.define do
  factory :sleep_record do
    association :user
    clocked_in_at { 8.hours.ago }
    state { "clocked_in" }
    duration { 0 }

    trait :clocked_out do
      clocked_out_at { Time.current }
      state { "clocked_out" }
      duration { (clocked_out_at - clocked_in_at).to_i }
    end
  end
end
