# frozen_string_literal: true

module SteerSuite
  class SteersimSceneInfo
    def initialize(scene, subdir: nil)
      @scene = scene
      @subdir = subdir
      @scene_config = CONFIG.dig("steersuite_scene", "basic", @scene)
    end

    def agent_former_config
      @scene_config
    end

    def parameter_size
      @scene_config["parameter_size"].to_i
    end

    def nagent
      @scene_config["nagent"].to_i
    end

    def data_location
      base = StorageLoader.get_path("#{@scene.tr("_", "-")}-base-data")
      base = File.join(base, @subdir) if @subdir
      {
        train: File.join(base, "train"),
        valid: File.join(base, "valid"),
        train20: File.join(base, "train-20fps"),
        valid20: File.join(base, "valid-20fps"),
        test: File.join(base, "test"),
        base: base
      }
    end

    def prepare_steer_sim_config!
      case @scene
      when /scene\d{1,4}/
        # based on scene name, config scene name is 'sceneBasic(%num)'
        default_scene_name = "sceneBasic#{@scene[/\d+/]}"
        scene_name = @scene_config.fetch("scene_name", default_scene_name)
      else
        scene_name = @scene_config.fetch("scene_name")
      end
      SteerSuite::SteersimConfigEditor.change_scene(scene_name)

      if @scene_config["ai"]
        SteerSuite::SteersimConfigEditor.set_ai(@scene_config["ai"])
      end
    end
  end
end
