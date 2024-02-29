#!/usr/bin/env -S ruby -Ilib
require "bundler/setup"
require "csv"

module STRATEGY; end
STRATEGY::NOINIT = true

args = {
  target_db: "/home/kaidong/Projects/RubymineProjects/ActiveLoop/storage/snapshots/sf3-homo-test-full/agentformer-result/metadata.sqlite3",
  desired_metric: "ple_energy"
}

require "parameter_object"

ParameterDatabase.establish_connection(target: :sqlite3, database: args[:target_db], copy: false)

def get_metric_from_text(content, metric)
  lines = content.lines
  keys = lines[1].split
  values = lines[2].split
  hash = keys.zip(values).to_h
  hash[metric]
end

maes_pred = []
maes_abls = []
puts "Scenario size: "
puts "ground: #{ParameterObject.where(label: "budget-ground").count} "
puts "prediction: #{ParameterObject.where(label: :prediction).count} "
puts "ablation: #{ParameterObject.where(label: :ablation).count} "
ParameterObject.where(label: "budget-ground").each do |ground|
  pred = ground.predicted_as.where(label: :prediction).first
  abla = ground.predicted_as.where(label: :ablation).first
  e1 = get_metric_from_text ground.benchmark.log, args[:desired_metric]
  ep = get_metric_from_text pred.benchmark.log, args[:desired_metric]
  ea = get_metric_from_text abla.benchmark.log, args[:desired_metric]
  maes_pred << (e1.to_f-ep.to_f).abs
  maes_abls << (e1.to_f-ea.to_f).abs
end

puts "From dataset #{File.split(args[:target_db])[-3..]}"
puts "Prediction averaged value #{maes_pred.sum/maes_pred.size}"
puts "Ablation averaged value #{maes_abls.sum/maes_abls.size}"
