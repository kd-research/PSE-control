require 'yaml'
require 'tqdm'
require 'pathname'
require 'fileutils'
require 'securerandom'
require_relative '../lib/active_learning/active_learning_caller'
require_relative '../lib/storage_loader'
require_relative '../lib/agent_former'
require_relative '../lib/steer_suite'
require_relative '../lib/parameter_object'

ParameterDatabase.establish_connection
ParameterDatabase.initialize_database(force: true)

$scene = $scene || 'scene1'
SteerSuite.set_info($scene)

$bycycle = $bycycle || false
$dummy = $dummy || false
$start_data = $start_data&.to_i || 4000

$jobmod = "activejob-#{Random.alphanumeric}"

def init_feeding
  def get_binary_filenames(dirname)
    Dir.glob("*.bin", base: dirname)
  end

  dirname = SteerSuite.info.data_location[:train20]
  get_binary_filenames(dirname).tqdm.each do |fname|
    pobj = ParameterObject.new(split: :train, state: :raw, label: 'budget-ground')
    fullpath = File.join(dirname, fname)
    SteerSuite.document(pobj, fullpath)
    pobj.save!
  end

  dirname = SteerSuite.info.data_location[:valid20]
  get_binary_filenames(dirname).tqdm.each do |fname|
    pobj = ParameterObject.new(split: :cross_valid, state: :raw, label: 'budget-ground')
    fullpath = File.join(dirname, fname)
    SteerSuite.document(pobj, fullpath)
    pobj.save!
  end
end

def init_feeding_batch
  def get_binary_filenames(dirname)
    Dir.glob("*.bin", base: dirname)
  end

  loop do
    $start_data.times.each do 
      pobj = ParameterObject.new(split: :train, state: :raw, label: 'budget-ground')
      pobj.safe_set_parameter(SteerSuite.info.parameter_size.times.map { rand })
      pobj.save!
    end

    SteerSuite.simulate_unsimulated
    break if ParameterObject.where(split: :train, state: :raw, label: 'budget-ground').count > $start_data
  end


  dirname = SteerSuite.info.data_location[:valid_20]
  get_binary_filenames(dirname).each do |fname|
    pobj = ParameterObject.new(split: :cross_valid, state: :raw, label: 'budget-ground')
    fullpath = File.join(dirname, fname)
    SteerSuite.document(pobj, fullpath)
    pobj.save!
  end

end

if $batch
  # init_feeding_batch
  init_feeding
else
  init_feeding
end

SteerSuite.mark_validation
$budget_base = ParameterObject.where(split: :train, state: :valid_raw, label: 'budget-ground').limit($start_data).pluck(:file)

def cycle_train(source_label:, target_label:nil, finalize: false)
  train_files = ParameterObject.where(split: :train, state: :valid_raw, label: source_label).pluck(:file) + $budget_base
  valid_files = ParameterObject.where(split: :cross_valid, state: :valid_raw, label: 'budget-ground').pluck(:file)
  test_files = []

  renderer = AgentFormer.renderer_instance
  epoch_suffix = if $bycycle
                   sprintf("_%06d", train_files.size)
                 else
                   ""
                 end
  renderer.set_data_source(train_files, valid_files, test_files)
  renderer.instance_variable_set :@model_suffix, '_' + $jobmod.tr('-', '_') + epoch_suffix
  renderer.instance_variable_set :@segmented, '-segmented'

  start_time = Time.now
  AgentFormer.call_agentformer
  puts "Agentformer #{source_label} training use #{Time.now - start_time} seconds"

  start_time = Time.now
  AgentFormer.call_latent_dump
  puts "Agentformer #{source_label} latent dump use #{Time.now - start_time} seconds"
  
  start_time = Time.now
  ActiveLearningCaller.keras_train(segmented: true)
  puts "Agentformer #{source_label} keras train use #{Time.now - start_time} seconds"
  if finalize
    # FileUtils.rm_rf(StorageLoader.get_path('agentformer-result'))
    return
  end

  start_time = Time.now
  ActiveLearningCaller.keras_sample_train(segmented: true, with_label: target_label, dummy: $dummy)

  SteerSuite.simulate_unsimulated
  abort "Simulation failed" unless SteerSuite.unprocessed.any?

  SteerSuite.mark_validation
  abort "Processing failed" unless SteerSuite.unprocessed.empty?

  puts "Agentformer #{source_label.last || "initial"} sample process use #{Time.now - start_time} seconds"
  renderer.instance_variable_set :@num_epochs, '1' unless $bycycle
end

batch_labels = []
(1..9).each {|i| batch_labels << "active-#{$jobmod}-#{i}"} unless $batch
ParameterObject.where(label: batch_labels).delete_all

renderer = AgentFormer.renderer_instance
renderer.instance_variable_set :@num_epochs, '1'

batch_labels.each_index do |idx|
  cycle_train(source_label: batch_labels[...idx], target_label: batch_labels[idx])
end

cycle_train(source_label: batch_labels, finalize: true)
