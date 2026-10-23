require_relative "lib/check_host"

Gem::Specification.new do |s|
  s.name = "check-host-one"
  s.version = CheckHost::VERSION
  s.summary = "Ruby client for check-host.one: ping, TCP ping, HTTP, traceroute and DNS checks from 100+ countries"
  s.authors = ["check-host.one"]
  s.homepage = "https://check-host.one"
  s.license = "MIT"
  s.files = ["lib/check_host.rb", "README.md", "LICENSE"]
  s.required_ruby_version = ">= 3.0"
  s.metadata = {
    "source_code_uri" => "https://github.com/Check-Host-one/check-host-ruby",
    "documentation_uri" => "https://check-host.one/docs#api",
  }
end
