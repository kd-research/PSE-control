#!/usr/bin/env -S ruby -Ilib
require "bundler/setup"

module ActiveLoopTools
  module LatentGenerate
    # Required for every time calling the latent generation
    # Three components needs to be prepared for the snapshot:
    # 1. The simulation metadata db (for further re-simulation)
    # 2. The AgentFormer model
    # 3. The Configuration Prediction Network (CPN) model
    # Metadata lives under trajectory folder with name "metadata.sqlite3"
    # metadata will be saved under agentformer_result directory
    # Trajectory folder extracted from the simulation database with given
    # scene id and subdir id
    # AgentFormer and CPN models are under agentformer_result directory
    #
    def prepare_snapshot(args)

      require "snapshot"
      Snapshot.recover_snapshot_from(args.result_path)

      require "steer_suite"
      require "parameter_object"
      require "agent_former"
      SteerSuite.set_info(args.scene_name, subdir: args.subdir)
      trajectory_path = SteerSuite.info.data_location[:test]
      metadata_path = File.join(trajectory_path, "metadata.sqlite3")
      copied = Snapshot.make_snapshot(metadata_path, subpath: "agentformer-result/")
      ParameterDatabase.establish_connection(target: :sqlite3, database: copied)
    end

    # Extract latent process requires AgentFormer model and the metadata
    # We need to prepare the AgentFormer configuration
    def extract_latents(args)
      all_files = ParameterObject.all.pluck(:file)
      config_renderer = AgentFormer.renderer_instance
      config_renderer.instance_eval do
        @segmented = "-evac"
        @extra = "agent_num: #{args.agent_num}"
        set_data_source([], [], all_files)
      end
      AgentFormer.call_latent_dump(for_phase: [:test])
    end

    module_function :prepare_snapshot, :extract_latents
  end
end

if __FILE__ == $0
  args = OpenStruct.new({
    scene_name: "scene_evac_sf_3",
    subdir: "homogeneous",
    af_result_path: File.join(ENV["HOME"], "Downloads"),
    agent_num: 10
  })

  ActiveLoopTools::LatentGenerate.prepare_snapshot(args)
  ActiveLoopTools::LatentGenerate.extract_latents(args)
end
