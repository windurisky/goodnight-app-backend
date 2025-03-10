module UserError
  class NotFound < HandledError
    def initialize
      super(
        "User is not found",
        :not_found
      )
    end
  end
end
