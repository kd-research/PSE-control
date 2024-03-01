#!/usr/bin/env -S ruby -Ilib
require "csv"

module ActiveLoopTools
  module BenchAnalyzer
    # Initialize the module when it is used as a standalone script
    # @param [Hash] args the arguments to initialize the module
    def standalone_init(args)
      require "parameter_object"
      ParameterDatabase.establish_connection(target: :sqlite3, database: args[:target_db], copy: false)
    end

    # @param [String] content the content of the log file
    # @param [String] metric the metric to extract
    # @return [String] the value of the metric
    def get_metric_from_text(content, metric)
      if content.nil?
        warn "No content"
        return 0
      end
      lines = content.lines
      keys = lines[1].split
      values = lines[2].split
      hash = keys.zip(values).to_h
      hash[metric]
    end

    # @param [String] label1 the label of the first parameter object
    # @param [String] label2 the label of the second parameter object
    # @param [String] metric the metric to compare
    def report_difference_for(label1, label2, metric)
      abs_diff_arr = []
      ParameterObject.where(label: label1).each do |p1|
        p2 = p1.predicted_as.where(label: label2).first
        if p2.nil?
          warn "No predicted parameter object for #{label2} for #{p1.id}"
          next
        end

        e1 = get_metric_from_text p1&.benchmark&.log, metric
        e2 = get_metric_from_text p2&.benchmark&.log, metric
        abs_diff_arr << (e1.to_f - e2.to_f).abs
      end
      abs_diff_arr.sum / abs_diff_arr.size
    end

    module_function :standalone_init, :get_metric_from_text, :report_difference_for
  end
end

if __FILE__ == $0
  require "bundler/setup"

  module STRATEGY; end
  STRATEGY::NOINIT = true

  args = {
    target_db: "/home/kaidong/Projects/RubymineProjects/ActiveLoop/storage/snapshots/activeloop-20240229-2303496-u4h2bf.snapshot/agentformer-result/metadata.sqlite3"
  }
  ActiveLoopTools::BenchAnalyzer.standalone_init(args)

  puts "Scenario size: "
  puts "ground: #{ParameterObject.where(label: "budget-ground").count} "
  puts "prediction: #{ParameterObject.where(label: :prediction).count} "
  puts "ablation: #{ParameterObject.where(label: :ablation).count} "

  pred = ActiveLoopTools::BenchAnalyzer.report_difference_for("budget-ground", "prediction", "ple_energy")
  puts "Prediction averaged value #{pred}"
  abls = ActiveLoopTools::BenchAnalyzer.report_difference_for("budget-ground", "ablation", "ple_energy")
  puts "Ablation averaged value #{abls}"
end
