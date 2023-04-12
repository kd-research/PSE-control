# frozen_string_literal: true

module SteerSuite
class SteersimSceneInfo
  def initialize(scene)
    @scene = scene
  end

  def parameter_size
    CONFIG.dig('steersuite_scene', 'basic', @scene, 'parameter_size').to_i
  end

  def nagent
    CONFIG.dig('steersuite_scene', 'basic', @scene, 'nagent').to_i
  end

  def data_location
    base = StorageLoader.get_path("#{@scene}-base-data")
    { train: File.join(base, 'train'), valid: File.join(base, 'valid'), test: File.join(base, 'test') }
  end

  def prepare_steer_sim_config!
    # based on scene name, config scene name is 'sceneBasic[1-4]'
    scene_name = "sceneBasic#{@scene[-1]}"
    SteerSuite::SteersimConfigEditor.change_scene(scene_name)
  end
end

end