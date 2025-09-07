#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "json"
require "mongo"
Mongo::Logger.logger.level = ::Logger::WARN

MONGO_URI = ENV.fetch("MONGO_URI", "mongodb://root:secret@localhost:27017/?authSource=admin")
DB_NAME   = ENV.fetch("MONGO_DB", "fxdb")

def base_rate_for(code)
  s = code.bytes.sum
  0.5 + (s % 151) / 100.0
end

currencies_path = File.expand_path("../currencies.json", __dir__)
currencies = JSON.parse(File.read(currencies_path))

base = {}
currencies.each { |c| base[c] = base_rate_for(c) }
base["USD"] = 1.0

client = Mongo::Client.new(MONGO_URI, database: DB_NAME)
coll   = client[:base_rates]

coll.replace_one({ _id: "latest" }, { _id: "latest", rates: base }, upsert: true)

puts "Seeded base_rates with #{base.size} currencies."