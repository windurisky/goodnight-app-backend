module FollowError
  class AlreadyFollowed < HandledError
    def initialize
      super(
        "You have already followed the user",
        :unprocessable_entity
      )
    end
  end

  class AlreadyUnfollowed < HandledError
    def initialize
      super(
        "You have already unfollowed the user",
        :unprocessable_entity
      )
    end
  end
end
