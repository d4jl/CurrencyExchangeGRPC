#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
GEN_DIR = File.expand_path("../gen/ruby", __dir__)
$LOAD_PATH.unshift(GEN_DIR) unless $LOAD_PATH.include?(GEN_DIR)

require "grpc"
require "currency_pb"
require "currency_services_pb"

def main
  stub = Fx::V1::CurrencyExchange::Stub.new("localhost:50051", :this_channel_is_insecure)

  req = Fx::V1::CurrencyExchangeRequest.new(
    base_currency:    Fx::V1::Currency::USD,
    desired_currency: Fx::V1::Currency::EUR,
    amount:           101.0
  )

  resp = stub.get_currency_exchange(req)
  puts "Converted amount: #{resp.amount}"
end

main if __FILE__ == $0
