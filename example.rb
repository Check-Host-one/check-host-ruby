# Live smoke test: ruby example.rb
require_relative "lib/check_host"

ch = CheckHost::Client.new
m = ch.traceroute("example.com", limit: 1, locations: ["Germany"])
raise "not finished" unless m["status"] == "finished"
m["results"].each { |r| puts "#{r["probe"]["city"]}, #{r["probe"]["country"]}: #{r["result"]["hops"].size} hops" }
puts "https://check-host.one/r/#{m["resultSlug"]}"
raise "hostinfo" unless ch.host_info("1.1.1.1")["asn"] == 13335
begin
  ch.get_measurement("nope")
  raise "want 404"
rescue CheckHost::Error => e
  raise e unless e.status == 404
end
