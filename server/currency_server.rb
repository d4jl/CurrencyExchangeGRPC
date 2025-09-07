#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"

GEN_DIR = File.expand_path("../gen/ruby", __dir__)
$LOAD_PATH.unshift(GEN_DIR) unless $LOAD_PATH.include?(GEN_DIR)
require "grpc"
require "currency_pb"
require "currency_services_pb"

require "mongo"
Mongo::Logger.logger.level = ::Logger::WARN
MONGO_URI = ENV.fetch("MONGO_URI", "mongodb://root:secret@localhost:27017/?authSource=admin")
DB_NAME   = ENV.fetch("MONGO_DB", "fxdb")

class CurrencyExchangeServer < Fx::V1::CurrencyExchange::Service
  def initialize
    @client = Mongo::Client.new(MONGO_URI, database: DB_NAME)
    @base_rates_coll = @client[:base_rates]
    @rates_cache = load_rates
    super
  end

  def get_currency_exchange(request, _call)
    base_sym = request.base_currency
    dest_sym = request.desired_currency
    from = base_sym.to_s
    to   = dest_sym.to_s

    unless @rates_cache.key?(from) && @rates_cache.key?(to)
      @rates_cache = load_rates
    end

    br_from = @rates_cache[from]
    br_to   = @rates_cache[to]

    if br_from.nil? || br_to.nil?
      fail GRPC::NotFound, "Missing base rate for #{from} or #{to}"
    end

    rate = br_to / br_from
    Fx::V1::CurrencyExchangeResponse.new(amount: request.amount * rate)
  end

  private

  def load_rates
    doc = @base_rates_coll.find(_id: "latest").first
    raise "base_rates doc not found; run the seeder" if doc.nil?
    doc["rates"].transform_values!(&:to_f)
  end
end

server = GRPC::RpcServer.new
server.add_http2_port("0.0.0.0:50051", :this_port_is_insecure)
server.handle(CurrencyExchangeServer)
puts "Server on :50051 (computing from base_rates)"
server.run_till_terminated