# frozen_string_literal: true

module BenchmarkLogActions # :nodoc:
  def define_benchmark_methods(*benchmark_types) # :nodoc:
    benchmark_types.each do |btype|
      module_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{btype}
          benchattr.fetch(:#{btype}).to_f
        end
      RUBY
    end
  end
  def initialize_database(force: false)
    connection.create_table :benchmark_log, force: force do |t|
      t.belongs_to :parameter_object
      t.text :log
      t.timestamps
    end
  end
end

# Model used to store benchmark record generated
# from steersuite
class BenchmarkLogs < ActiveRecord::Base
  ALL_BENCHES = %i[total_acceleration total_distance_traveled
                   total_change_in_speed total_degrees_turned
                   ple_energy ple_energy_optimal ple_energy_ratio].freeze
  extend BenchmarkLogActions

  self.table_name = 'benchmark_log'
  belongs_to :parameter_object

  def benchattr
    _, ks, vs = log.lines
    ks.split.zip(vs.split).to_h.symbolize_keys
  end

  define_benchmark_methods(*ALL_BENCHES)
end
