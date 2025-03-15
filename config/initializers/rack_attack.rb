class Rack::Attack
  # Allow whitelisted IPs (e.g., internal services, monitoring tools)
  safelist('allow-localhost') do |req|
    # Allow all requests from localhost
    req.ip == '127.0.0.1' || req.ip == '::1'
  end

  # Throttle overall requests (100 requests per 1 minute per IP)
  throttle('req/ip', limit: 100, period: 1.minute) do |req|
    req.ip
  end

  # Throttle login attempts (5 requests per minute per IP)
  throttle('logins/ip', limit: 5, period: 1.minute) do |req|
    req.ip if req.path == '/api/v1/auth/login' && req.post?
  end

  # Blocklist abusive IPs (e.g., detected attackers)
  blocklist('block-bad-actors') do |req|
    # Example blocked IPs, could be from ENV or other sources
    bad_ips = ['192.168.1.100', '10.0.0.200']
    bad_ips.include?(req.ip)
  end

  # Custom response for blocked requests
  self.blocklisted_response = lambda do |_env|
    [ 429, { 'Content-Type' => 'application/json' }, [{ error: "Too many requests. Try again later." }.to_json] ]
  end
end

Rails.application.config.middleware.use Rack::Attack
