#!/usr/bin/env ruby
require_relative "../snapshot"
require_relative "../config_loader"

module ParameterDatabase
  extend ConfigLoader
  ALL_RECORDS = [
    ParameterObject, ParameterObjectRelation, BenchmarkLogs
  ].freeze

  module_function

  def establish_connection(target: :default, **kwargs)
    return if ActiveRecord::Base.connected?

    db_config = load_config("config/database.yml")
    # db_config.symbolize_keys!

    do_copy = kwargs.fetch(:copy, true)
    c = db_config[target.to_s]
    raise "No such database: #{target}" if c.nil?
    c.update(kwargs.slice(:database, :username, :password, :host, :port))

    if c["adapter"] == "sqlite3" && !c["database"].start_with?(":memory:")
      FileUtils.mkdir_p(File.expand_path(File.dirname(c["database"])))
      if do_copy
        c["database"] = Snapshot.make_snapshot(c["database"], copy: File.exist?(c["database"]))
      end
    end

    puts "Connecting to #{c.inspect}" if $DEBUG
    ActiveRecord::Base.establish_connection(c)
  end

  def initialize_database(...)
    ParameterDatabase::ALL_RECORDS.each do |r|
      r.initialize_database(...)
    rescue Exception => e
      raise unless e.message.match?(/already exists/)
      puts e.message
    end
  end

  def load_from_directory(dirname, **kwargs)
    valid_method = kwargs.delete(:valid_method)
    abort "No such directory: #{dirname}" unless Dir.exist? dirname
    files = Dir.glob(File.join(dirname, "*.bin"))
    abort "No files found in #{dirname}" if files.empty?
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
    when nil
      # do nothing
    else
      raise ArgumentError, "invalid valid_method: #{valid_method}"
    end
  end
end
