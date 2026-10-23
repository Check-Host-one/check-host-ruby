# frozen_string_literal: true

# Ruby client for the check-host.one API: ping, TCP ping, HTTP, traceroute and
# DNS checks from servers in 100+ countries. No API key is needed.

require "json"
require "net/http"
require "uri"

module CheckHost
  VERSION = "1.0.0"

  # An error response from the API. retry_after (seconds) is set on 429.
  class Error < StandardError
    attr_reader :status, :type, :retry_after

    def initialize(status, type, message, retry_after = nil)
      super("#{status} #{type}: #{message}")
      @status = status
      @type = type
      @retry_after = retry_after
    end
  end

  class Client
    def initialize(base_url: "https://check-host.one", timeout: 30)
      @base = URI(base_url.chomp("/"))
      @timeout = timeout
    end

    # POST /api/v1/measurements. Returns {"id" => ..., "probesCount" => ...}.
    def create_measurement(request) = request(:post, "/api/v1/measurements", request)
    def get_measurement(id) = request(:get, "/api/v1/measurements/#{enc(id)}")
    # A saved result, kept for 90 days, also at https://check-host.one/r/{slug}.
    def get_result(slug) = request(:get, "/api/v1/results/#{enc(slug)}")
    # ASN, operator and location. nil looks up the caller's own address.
    def host_info(target = nil) = request(:get, "/api/v1/hostinfo#{"?target=#{enc(target)}" if target}")
    def probes = request(:get, "/api/v1/probes")
    def stats = request(:get, "/api/v1/stats")

    # Start a check and poll once a second until it finishes (max ~60 s).
    # locations are free-form: country code, city, continent, ASN or network name.
    def run(type, target, limit: 5, locations: [], options: nil)
      req = { type: type, target: target, limit: limit }
      req[:locations] = locations.map { |l| { magic: l } } unless locations.empty?
      req[:measurementOptions] = options if options
      id = create_measurement(req)["id"]
      m = get_measurement(id)
      60.times do
        break unless m["status"] == "in-progress"

        sleep 1
        m = get_measurement(id)
      end
      m
    end

    def ping(target, packets: 3, **kw) = run("ping", target, options: { packets: packets }, **kw)
    def tcp_ping(target, port: 443, **kw) = run("ping", target, options: { protocol: "TCP", port: port }, **kw)

    def http(target, method: "HEAD", path: "/", protocol: "HTTPS", **kw)
      run("http", target, options: { protocol: protocol, request: { method: method, path: path } }, **kw)
    end

    def traceroute(target, protocol: "ICMP", **kw) = run("traceroute", target, options: { protocol: protocol }, **kw)
    def dns(target, record: "A", **kw) = run("dns", target, options: { query: { type: record } }, **kw)

    private

    def enc(s) = URI.encode_www_form_component(s).gsub("+", "%20")

    def request(method, path, body = nil)
      uri = URI(@base.to_s + path)
      req = (method == :post ? Net::HTTP::Post : Net::HTTP::Get).new(uri)
      req["Content-Type"] = "application/json"
      req["Accept"] = "application/json"
      req["User-Agent"] = "check-host-ruby/#{VERSION}"
      req.body = JSON.generate(body) if body
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                            open_timeout: @timeout, read_timeout: @timeout) { |h| h.request(req) }
      data = JSON.parse(res.body.to_s.empty? ? "{}" : res.body)
      return data if res.is_a?(Net::HTTPSuccess)

      err = data["error"] || {}
      retry_after = res["Retry-After"]&.to_i
      raise Error.new(res.code.to_i, err["type"] || "http_error", err["message"] || res.message, retry_after)
    end
  end
end
