# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
require "etc"


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

# Ensure the database connection is closed before forking
ActiveRecord::Base.connection.disconnect!

def generate_ten_million_user_data(num_processes: 6)
  pids = []

  num_processes.times do |i|
    pids << fork do
      begin
        # Reconnect to database inside the child process
        ActiveRecord::Base.establish_connection

        base_user = User.find_by(username: "windu_risky") # Refetch in each process

        puts "Process #{Process.pid} started (Worker ##{i + 1})"

        (10_000_000 / num_processes).times do |index|
          start = 8.days.ago

          user = User.create!(
            username: Faker::Internet.username(specifier: 8..20),
            password: "password",
            name: Faker::Name.name
          )

          if rand(2) == 1 && base_user.followings.count < 10_000
            begin
              Socials::FollowService.call(user: base_user, target_user_id: user.id)
            rescue StandardError => e
              puts "FollowService error: #{e.message}"
            end
          end

          1_000.times do
            break if start > Time.current

            duration = rand(8.hours.to_i).to_i

            sleep_record = SleepRecord.create!(
              user: user,
              clocked_in_at: start,
              clocked_out_at: start + duration,
              duration: duration,
              state: :clocked_in
            )
            sleep_record.clock_out!

            start += duration
          end

          puts "[Process #{Process.pid}] Created user #{user.username} (#{index + 1} in worker ##{i + 1})"
        rescue StandardError => e
          puts "[Process #{Process.pid}] Error: #{e.message}"
          puts e.backtrace.first(5)
        end
      ensure
        ActiveRecord::Base.connection.close
        puts "Process #{Process.pid} exiting..."
      end

      exit
    end
  end

  # Wait for all forked processes to finish
  pids.each { |pid| Process.wait(pid) }
end

# Uncomment the lines below to run 10 millions of user and sleep record seeding

# puts "your processor = #{Etc.nprocessors} core(s)"
# num_processes = (Etc.nprocessors * 0.8).floor
# puts "you will be using 80% of it: #{num_processes} core(s)"
# sleep(3)
# generate_ten_million_user_data(num_processes: num_processes)

puts "Seeds completed!"
