class HandledError < StandardError
  attr_reader :http_code, :code

  def initialize(message, http_code = :internal_server_error, code = nil)
    super(message)
    @http_code = http_code
    @code = code.presence || http_code.to_s
  end
end
