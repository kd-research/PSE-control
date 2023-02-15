require 'yaml'
require 'tqdm'
require 'pathname'
require 'fileutils'
require_relative '../lib/active_learning/active_learning_caller'
require_relative '../lib/storage_loader'
require_relative '../lib/agent_former'
require_relative '../lib/parameter_object'
require_relative '../lib/parameter_object_relation'
require_relative '../lib/steer_suite'



ParameterObject.establish_connection

# Establish connection and reset the database
def initialize_db
  ParameterObject.initialize_database(force: true)
  ParameterObjectRelation.initialize_database(force: true)
end

# Initialize database with random 500 training samples
def init_feeding
  def get_binary_filenames(dirname)
    Dir.glob("*.bin", base: dirname)
  end

  dirname = '/home/kaidong/RubymineProjects/ActiveLoop/storage/steersimRecord-train'
  get_binary_filenames(dirname).sample(1000).tqdm.each do |fname|
    pobj = ParameterObject.new(split: :train, state: :processed)
    fullpath = File.join(dirname, fname)
    SteerSuite.document(pobj, fullpath)
    pobj.save!
  end

  dirname = '/home/kaidong/RubymineProjects/ActiveLoop/storage/steersimRecord-cv'
  get_binary_filenames(dirname).tqdm.each do |fname|
    pobj = ParameterObject.new(split: :cross_valid, state: :processed)
    fullpath = File.join(dirname, fname)
    SteerSuite.document(pobj, fullpath)
    pobj.save!
  end
end

def cycle_train(finalize: false)
  train_files = ParameterObject.where(split: :train, state: :processed).pluck(:file)
  valid_files = ParameterObject.where(split: :cross_valid, state: :processed).pluck(:file)
  test_files = []

  renderer = AgentFormer.renderer_instance
  renderer.set_data_source(train_files, valid_files, test_files)
  AgentFormer.call_agentformer(renderer)
  AgentFormer.call_latent_dump

  ActiveLearningCaller.keras_train
  if finalize
    FileUtils.rm_rf(StorageLoader.get_path('agentformer-result'))
    return
  end

  ActiveLearningCaller.keras_sample_train
  SteerSuite.simulate_unsimulated
  SteerSuite.process_unprocessed
end

initialize_db
init_feeding
9.times { cycle_train(finalize: false) }
cycle_train(finalize: true)