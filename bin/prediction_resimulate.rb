#!/usr/bin/env -S ruby -Ilib

require 'bundler/setup'
require 'ostruct'
require 'json'

require 'ActiveLoopTools/LatentGenerate'
require 'ActiveLoopTools/ConfigParamGenerate'
require 'ActiveLoopTools/LoadPredictions'
require 'ActiveLoopTools/BenchAnalyzer'

argarr = ARGV[0].split(',')
subdir_map = {
  "identity" => "homogeneous",
  "fullrandom" => "heterogeneous",
}

args = OpenStruct.new(
  trial_name: argarr[0],
  scene_name: "scene_evac_#{argarr[1]}",
  subdir: subdir_map[argarr[2]],
  result_path: argarr[3],
  agent_num: 10,
)

alt = ActiveLoopTools
alt::LatentGenerate.prepare_snapshot(args)
# In testing phase, we delete all the parameters except for the first two
# ParameterObject.where.not(id: ParameterObject.select(:id).limit(2)).delete_all
alt::LatentGenerate.extract_latents(args)
alt::ConfigParamGenerate.generate_config
alt::LoadPredictions.load_prediction
alt::LoadPredictions.load_ablation
SteerSuite.simulate_unsimulated

report_hash = args.to_h
report_hash[:pred_diff] = alt::BenchAnalyzer.report_difference_for('budget-ground', 'prediction', 'ple_energy')
report_hash[:ablation_diff] = alt::BenchAnalyzer.report_difference_for('budget-ground', 'ablation', 'ple_energy')

puts "@Report #{report_hash.to_json}"
