# frozen_string_literal: true

module SteerSuite
  class SteersimSceneInfo
    def initialize(scene)
      @scene = scene
      @scene_config = CONFIG.dig('steersuite_scene', 'basic', @scene)
    end

    def parameter_size
      @scene_config['parameter_size'].to_i
    end

    def nagent
      @scene_config['nagent'].to_i
    end

    def data_location
      base = StorageLoader.get_path("#{@scene}-base-data")
      {
        train: File.join(base, 'train'),
        valid: File.join(base, 'valid'),
        train20: File.join(base, 'train-20fps'),
        valid20: File.join(base, 'valid-20fps'),
        test: File.join(base, 'test'),
        base: base
      }
    end

    def prepare_steer_sim_config!
      # based on scene name, config scene name is 'sceneBasic(%num)'
      default_scene_name = "sceneBasic#{@scene[/\d+/]}"
      scene_name = @scene_config.fetch('scene_name', default_scene_name)
      SteerSuite::SteersimConfigEditor.change_scene(scene_name)
    end
  end

end
