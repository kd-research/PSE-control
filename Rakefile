# frozen_string_literal: true


require 'yaml'
require 'parallel'
namespace :steersuite do
  require_relative 'lib/parameter_object'
  require_relative 'lib/steer_suite'
  ParameterObject.establish_connection

  config = YAML.safe_load(File.open('config/steersuite.yml'))

  task auto_simulate: :clean do
    SteerSuite.simulate_unsimulated
  end

  task :clean do
    rm_rf(StorageLoader.get_path(config['steersuite_record_pool']), secure: true)
  end
end

namespace :db do
  require 'active_record'
  require_relative 'lib/parameter_object'

  task :init, :force do |_, args|
    ParameterObject.establish_connection
    ParameterObject.initialize_database(force: args[:force])
    ParameterObjectRelation.initialize_database(force: args[:force])
  end

  task :init_test, :force do |_, args|
    args.with_defaults(force: false)
    ParameterObject.establish_connection(target: :test)
    ParameterObject.initialize_database(force: args[:force])
    ParameterObjectRelation.initialize_database(force: args[:force])
  end

  task :reset_test do
    Rake::Task['db:init_test'].invoke(force: true)
  end

  task :reset do
    Rake::Task['db:init'].invoke(force: true)
  end

  task clean: :reset
end
