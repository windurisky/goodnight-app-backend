module SleepError
  class AlreadyClockedIn < HandledError
    def initialize
      super("You are already clocked in, must clock out first", :bad_request, "already_clocked_in")
    end
  end

  class AlreadyClockedOut < HandledError
    def initialize
      super("You are already clocked out, must clock in first", :bad_request, "already_clocked_out")
    end
  end
end
