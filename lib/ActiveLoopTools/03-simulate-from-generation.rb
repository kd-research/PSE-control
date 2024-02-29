#!/usr/bin/env -S ruby -Ilib
require "bundler/setup"
require "json"

module ActiveLoopTools
  module LoadPredictions
    def standalone_init(args)
      require "snapshot"
      Snapshot.reuse_snapshot!(args.af_result_path)

      require "steer_suite"
      require "parameter_object"
      require "active_learning"
      SteerSuite.set_info(args.scene_name, subdir: args.subdir)
      metadata_path = File.join(args.af_result_path, "agentformer-result", "metadata.sqlite3")
      ParameterDatabase.establish_connection(target: :sqlite3, database: metadata_path, copy: false)
    end

    def load_prediction(af_result_path)
      prediction_file = File.join(ActiveLearningCaller.working_dir, "test-prediction.json")
      File.readlines(prediction_file).map do |line|
        datum = JSON.parse(line)
        old = ParameterObject.where("file LIKE ?", "%#{datum["s"]}.bin").first
        new = ParameterObject.new(split: :test, state: :raw, label: :prediction)
        new.safe_set_parameter(datum["p"])
        new.predicted_from = old
        new.save!
      end

    end

    def load_ablation(af_result_path)
      prediction_file = File.join(ActiveLearningCaller.working_dir, "test-ablation.json")
      File.readlines(prediction_file).map do |line|
        datum = JSON.parse(line)
        old = ParameterObject.where("file LIKE ?", "%#{datum["s"]}.bin").first
        new = ParameterObject.new(split: :test, state: :raw, label: :ablation)
        new.safe_set_parameter(datum["p"])
        new.predicted_from = old
        new.save!
      end
    end

    module_function :standalone_init, :load_prediction, :load_ablation
  end
end

if __FILE__ == $0
  module STRATEGY; end
  STRATEGY::NOINIT = true

  args = OpenStruct.new({
    scene_name: "scene_evac_sf_2",
    subdir: "homogeneous",
    af_result_path: "/home/kaidong/Projects/RubymineProjects/ActiveLoop/storage/snapshots/sf3-homo-test-full",
    agent_num: 10
  })

  ActiveLoopTools::LoadPredictions.standalone_init(args)
  ActiveLoopTools::LoadPredictions.load_prediction(args.af_result_path)
  ActiveLoopTools::LoadPredictions.load_ablation(args.af_result_path)
  SteerSuite.simulate_unsimulated
end

