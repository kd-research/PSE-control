#!/usr/bin/env -S ruby -s -Ilib

require 'bundler/setup'
require 'ostruct'
require "ActiveLoopTools/BenchAnalyzer"

ab = ActiveLoopTools::BenchAnalyzer

ab.standalone_init(target_db: File.join(ENV['HOME'], 'Downloads', "metadata.sqlite3"))
puts "ground: #{ParameterObject.where(label: "budget-ground").count} "
puts "prediction: #{ParameterObject.where(label: :prediction).count} "
puts "ablation: #{ParameterObject.where(label: :ablation).count} "
puts ab.report_difference_for("budget-ground", "prediction", "ple_energy")
puts ab.report_difference_for("budget-ground", "ablation", "ple_energy")
