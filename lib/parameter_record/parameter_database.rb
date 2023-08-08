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
    c['database'] = Snapshot.make_snapshot(c['database'], copy: false) if c['adapter'] == 'sqlite3'

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

  def load_from_directory(dirname, **kwargs)
    valid_method = kwargs.delete(:valid_method) || :mark_only
    files = Dir.glob(File.join(dirname, '*.bin'))
    files = files.tqdm if $stdout.isatty

    files.each do |fname|
      pobj = ParameterObject.new(**kwargs)
      SteerSuite.document(pobj, fname)
      pobj.save!
    end

    case valid_method
    when :mark_only
      ParameterObject.where(**kwargs).update_all(state: :valid_raw)
    when :validate
      SteerSuite.validate_raw(remove: false)
    when :validate_and_clean
      SteerSuite.validate_raw(remove: true)
    end
  end
end
