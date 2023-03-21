#!/usr/bin/env ruby
require_relative '../config_loader'

module ParameterDatabase
  extend ConfigLoader
  ALL_RECORDS = [
    ParameterObject, ParameterObjectRelation, BenchmarkLogs
  ].freeze

  module_function

  def establish_connection(target: :default)
    return if ActiveRecord::Base.connected?

    db_config = load_config('config/database.yml')
    db_config.symbolize_keys!
    ActiveRecord::Base.establish_connection(db_config[target])
  end

  def initialize_database(...)
    ParameterDatabase::ALL_RECORDS.each do |r|
      r.initialize_database(...)
    rescue Exception => e
      raise unless e.message.match? /already exists/
      puts e.message
    end
  end
end
