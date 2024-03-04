#!/usr/bin/env -S ruby -s -Ilib

require 'bundler/setup'
require 'pry'
require 'ostruct'
require 'active_record'

require "ActiveLoopTools/BenchAnalyzer"




def batch_diff_report(target_db)
  ab = ActiveLoopTools::BenchAnalyzer
  ab.standalone_init(target_db: target_db)
  report = {target_db: target_db}
  metrics = %w(collisionTotal time total_distance_traveled ple_energy)
  metrics.each do |metric|
    pdiff = ab.report_difference_for("budget-ground", "prediction", metric)
    adiff = ab.report_difference_for("budget-ground", "ablation", metric)
    report[metric] = {pdiff: pdiff, adiff: adiff}
  end
  puts "@Report: #{report.to_json}"
rescue ZeroDivisionError => e
  puts "Error: #{target_db} is not available"
ensure
  ActiveRecord.disconnect_all!
end

ARGV.each do |target_db|
  batch_diff_report(target_db)
end
