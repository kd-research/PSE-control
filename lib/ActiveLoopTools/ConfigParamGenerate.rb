#!/usr/bin/env -S ruby -Ilib
require "bundler/setup"
require "ostruct"

module ActiveLoopTools
  module ConfigParamGenerate
    # Init is only required if the tool is running as a standalone script
    # @param [OpenStruct] args
    # @return [void]
    def standalone_init(args)
      require "snapshot"
      Snapshot.reuse_snapshot!(args.af_result_path)

      require "steer_suite"
      SteerSuite.set_info(args.scene_name, subdir: args.subdir)
    end

    def generate_config
      require "active_learning"

      ActiveLearningCaller.keras_predict(:test, ablation: false)
      ActiveLearningCaller.keras_predict(:test, ablation: true)
    end

    module_function :standalone_init, :generate_config
  end
end

if __FILE__ == $0
  args = OpenStruct.new({
    scene_name: "scene_evac_sf_3",
    subdir: "homogeneous",
    af_result_path: "/home/kaidong/Projects/RubymineProjects/ActiveLoop/storage/snapshots/sf3-homo-test-full",
    agent_num: 10
  })

  module STRATEGY; end
  STRATEGY::NOINIT = true
  ActiveLoopTools::ConfigParamGenerate.standalone_init(args)
  ActiveLoopTools::ConfigParamGenerate.generate_config
end
