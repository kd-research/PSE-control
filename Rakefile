# frozen_string_literal: true

require "yard"
require "yaml"
require "parallel"
require "minitest/test_task"

YARD::Rake::YardocTask.new do |t|
  t.files = ["lib/**/*.rb", "bin/**/*.rb"]
  t.options = ["--protected"]
end

Minitest::TestTask.create(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.warning = false
  t.test_globs = ["tests/**/*_test.rb"]
end

namespace :steersuite do
  task auto_simulate: :clean do
    require_relative "lib/parameter_object"
    require_relative "lib/steer_suite"
    ParameterDatabase.establish_connection

    SteerSuite.simulate_unsimulated
  end

  task :clean do
    config = YAML.safe_load(File.open("config/steersuite.yml"))
    rm_rf(StorageLoader.get_path(config["steersuite_record_pool"]), secure: true)
  end
end

namespace :db do
  task :init, :force do |_, args|
    require "active_record"
    require_relative "lib/parameter_object"

    ParameterObject.establish_connection
    ParameterObject.initialize_database(force: args[:force])
    ParameterObjectRelation.initialize_database(force: args[:force])
  end

  task :init_test, :force do |_, args|
    require "active_record"
    require_relative "lib/parameter_object"

    args.with_defaults(force: false)
    ParameterObject.establish_connection(target: :test)
    ParameterObject.initialize_database(force: args[:force])
    ParameterObjectRelation.initialize_database(force: args[:force])
  end

  task :reset_test do
    Rake::Task["db:init_test"].invoke(force: true)
  end

  task :reset do
    Rake::Task["db:init"].invoke(force: true)
  end

  task clean: :reset
end

task :default do
  puts Dir.pwd
  ruby "bin/tools/update_metadata_file_loc.rb"
end
