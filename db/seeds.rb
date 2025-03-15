# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

User.create!(
  username: "windu_risky",
  password: "password",
  name: "Windu Risky"
)

User.create!(
  username: "luke_skywalker",
  password: "password",
  name: "Luke Skywalker"
)

User.create!(
  username: "darth_vader",
  password: "password",
  name: "Darth Vader"
)

# Adjust num_processes based on CPU cores
def generate_ten_millions_user_data(num_processes: 6)
  pids = []

  num_processes.times do
    pids << fork do
      begin
        ActiveRecord::Base.connection.reconnect! # Ensure DB connection works in forked process

        (10_000_000 / num_processes).times do
          start = 8.days.ago

          user = User.create!(
            username: Faker::Internet.username(specifier: 8..20),
            password: "password",
            name: Faker::Name.name
          )

          if rand(2) == 1 && base_user.followings.count < 10_000
            Socials::FollowService.call(user: base_user, target_user_id: user.id)
          end

          1_000.times do
            break if start > Time.current

            duration = rand(8.hours.to_i)

            sleep_record = SleepRecord.create!(
              user: user,
              clocked_in_at: start,
              clocked_out_at: start + duration,
              duration: duration,
              state: :clocked_out
            )
            UpdateSleepTimelineJob.perform_now(sleep_record.id)

            start += duration
          end

          puts "Created #{user.username} user data"
        end
      rescue StandardError => e
        puts "Process #{Process.pid} encountered an error: #{e.message}"
        puts e.backtrace.first(5) # Show first 5 lines of error trace

      ensure
        ActiveRecord::Base.connection.close # Close DB connection when done
      end

      exit # Make sure each process exits properly
    end
  end

  # Wait for all forked processes to finish
  pids.each { |pid| Process.wait(pid) }
end

generate_ten_millions_user_data

puts "Seeds completed!"
