#!/usr/bin/env ruby
require_relative '../snapshot'
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

    c = db_config[target]
    if c['adapter'] == 'sqlite3'
      c['database'] = Snapshot.make_snapshot(c['database'], copy: false)
    end

    ActiveRecord::Base.establish_connection(c)
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
