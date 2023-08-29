# frozen_string_literal: true

require_relative 'test_helper'
class ActiveLearningTest < Minitest::Test
  def setup
    $agentformer_preserve = true
    Snapshot.set_snapshot_base(Dir.tmpdir)
    AgentFormer.reinitialize!
    ActiveLearningCaller.reinitialize!

    setup_agentformer_config_instance
  end

  def test_default_cycle
    setup_default_scene

    execute_one_cycle
  end

  def test_default_cycle_again
    setup_default_scene

    execute_one_cycle
  end

  %w[scene1 scene2 scene3 scene4].each do |scene|
    define_method("test_external_scene_#{scene}") do
      scene_path = StorageLoader.get_path("#{scene}-base-data")
      skip("external scene is not set") unless Dir.exist?(scene_path)

      setup_external_scene(scene_path, n:10)
      SteerSuite.set_info(scene)
      execute_one_cycle
    end
  end

  private

  def execute_one_cycle
    assert agentformer_path.start_with?(Snapshot::SNAPSHOT_PATH ),
           "agentformer path #{agentformer_path} is not a child of the snapshot base #{Snapshot::SNAPSHOT_PATH}"

    AgentFormer.call_agentformer
    model_path = File.join(agentformer_path, 'models')
    assert Dir.exist?(model_path), "model path #{model_path} does not exist"
    refute Dir.empty?(model_path), "model path #{model_path} is empty"

    AgentFormer.call_latent_dump
    latent_path = File.join(agentformer_path, 'latents')
    %w[train val].each do |mode|
      target_file = File.join(latent_path, "#{mode}.json")
      assert File.exist?(target_file), "latent file #{target_file} does not exist"
    end

    ActiveLearningCaller.keras_train(epochs: 1)
    assert File.exist?(File.join(latent_path, 'result_model.index')), "result model does not exist in #{latent_path}"

    sample = ActiveLearningCaller.keras_sample_train(noparse: true, count: 1)
    assert_equal 1, sample.lines.size, "sample size does not match"
  end

  def setup_agentformer_config_instance
    @instance = AgentFormer.renderer_instance
    @instance.instance_variable_set(:@suffix, '_test')
    @instance.instance_variable_set(:@num_epochs, 1)
  end

  def setup_default_scene
    @instance.set_data_source(
      [TestAsset.get_path('steersim_binary/sample1.bin')], [TestAsset.get_path('steersim_binary/sample2.bin')], [])
    SteerSuite.set_info('scene1')
  end

  def setup_external_scene(path, n:)
    absoulte_path = File.absolute_path(path)
    train_list = Dir.glob(File.join(absoulte_path, 'train', '*.bin')).sample(n)
    valid_list = Dir.glob(File.join(absoulte_path, 'valid', '*.bin')).sample(n)
    test_list = []
    refute_empty train_list, "train list is empty"
    refute_empty valid_list, "valid list is empty"
    @instance.set_data_source(train_list, valid_list, test_list)
  end

  def agentformer_path
    result_root_dir = @instance['results_root_dir']
    File.join(result_root_dir, @instance['as'])
  end
end
