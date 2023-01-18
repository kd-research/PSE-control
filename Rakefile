# frozen_string_literal: true


require 'yaml'
require 'parallel'
namespace :steersuite do
  require_relative 'lib/parameter_object'
  require_relative 'lib/steersim_worker'
  ParameterObject.establish_connection

  task :auto_simulate do
    unsimulated = ParameterObject.where(file: nil)
                                 .or(ParameterObject.where(file: ''))
    Parallel.each(unsimulated, progress: "Simulate") { |pobj| SteersimWorker.simulate(pobj) }
  end
end

namespace :db do
  require 'active_record'
  require_relative 'lib/parameter_object'
  ParameterObject.establish_connection

  task :initialize do
    ParameterObject.initialize_database
  end

  task :reset do
    ParameterObject.initialize_database(force: true)
  end
end
