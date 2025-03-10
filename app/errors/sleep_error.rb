module SleepError
  class AlreadyClockedIn < HandledError
    def initialize
      super("You are already clocked in, must clock out first", :bad_request, "already_clocked_in")
    end
  end

  class NotClockedIn < HandledError
    def initialize
      super("You are not clocked in, must clock in first", :bad_request, "not_clocked_in")
    end
  end
end
