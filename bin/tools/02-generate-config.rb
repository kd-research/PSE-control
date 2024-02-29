#!/usr/bin/env -S ruby -Ilib
require "bundler/setup"
require 'ostruct'

module STRATEGY; end
STRATEGY::NOINIT = true

require "snapshot"

args = OpenStruct.new({
  scene_name: "scene_evac_sf_3",
  subdir: "homogeneous",
  af_result_path: "/home/kaidong/Projects/RubymineProjects/ActiveLoop/storage/snapshots/sf3-homo-test-full",
  agent_num: 10
})

Snapshot.reuse_snapshot!(args.af_result_path)

require "steer_suite"
require "parameter_object"
require "active_learning"

SteerSuite.set_info(args.scene_name, subdir: args.subdir)

ActiveLearningCaller.keras_predict(:test, ablation: false)
ActiveLearningCaller.keras_predict(:test, ablation: true)


