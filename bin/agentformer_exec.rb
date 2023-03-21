require 'yaml'
require 'tqdm'
require 'pathname'
require 'fileutils'
require_relative '../lib/active_learning/active_learning_caller'
require_relative '../lib/storage_loader'
require_relative '../lib/agent_former'
require_relative '../lib/steer_suite'
require_relative '../lib/parameter_object'

ParameterDatabase.establish_connection
ParameterDatabase.initialize_database

def init_feeding
  def get_binary_filenames(dirname)
    Dir.glob("*.bin", base: dirname)
  end

  dirname = './storage/steersimRecord-train'
  get_binary_filenames(dirname).tqdm.each do |fname|
    pobj = ParameterObject.new(split: :train, state: :processed, label: 'budget-ground')
    pobj.label = "budget-ground"
    fullpath = File.join(dirname, fname)
    SteerSuite.document(pobj, fullpath)
    pobj.save!
  end

  dirname = './storage/steersimRecord-cv'
  get_binary_filenames(dirname).tqdm.each do |fname|
    pobj = ParameterObject.new(split: :cross_valid, state: :processed, label: 'budget-ground')
    pobj.label = "budget-ground"
    fullpath = File.join(dirname, fname)
    SteerSuite.document(pobj, fullpath)
    pobj.save!
  end
end

init_feeding
$budget_base = ParameterObject.where(split: :train, state: :processed, label: 'budget-ground').limit(1000).pluck(:file)
$bycycle = true
$dummy = false
$jobmod = "active-#{'no' if $bycycle }cont-#{$dummy? 'dummy': 'batch'}"

def cycle_train(source_label:, target_label:nil, finalize: false)
  train_files = ParameterObject.where(split: :train, state: :processed, label: source_label).pluck(:file) + $budget_base
  valid_files = ParameterObject.where(split: :cross_valid, state: :processed, label: 'budget-ground').pluck(:file)
  test_files = []

  renderer = AgentFormer.renderer_instance
  epoch_suffix = if $bycycle
                   sprintf("_%06d", train_files.size)
                 else
                   ""
                 end
  renderer.instance_variable_set :@model_suffix, '_ae_' + $jobmod.tr('-', '_') + epoch_suffix
  renderer.set_data_source(train_files, valid_files, test_files)

  start_time = Time.now
  puts AgentFormer.call_agentformer
  puts "Agentformer #{source_label} training use #{Time.now - start_time} seconds"

  start_time = Time.now
  AgentFormer.call_latent_dump
  puts "Agentformer #{source_label} latent dump use #{Time.now - start_time} seconds"
  
  start_time = Time.now
  ActiveLearningCaller.keras_train
  puts "Agentformer #{source_label} keras train use #{Time.now - start_time} seconds"
  if finalize
    # FileUtils.rm_rf(StorageLoader.get_path('agentformer-result'))
    return
  end

  start_time = Time.now
  ActiveLearningCaller.keras_sample_train(with_label: target_label, dummy: $dummy)
  SteerSuite.simulate_unsimulated
  SteerSuite.process_unprocessed
  puts "Agentformer #{source_label.last || "initial"} sample process use #{Time.now - start_time} seconds"
  renderer.instance_variable_set :@num_epochs, '2' unless $bycycle
end

batch_labels = []
(1..9).each {|i| batch_labels << "active-#{$jobmod}-#{i}"}
ParameterObject.where(label: batch_labels).delete_all

batch_labels.each_index do |idx|
  cycle_train(source_label: batch_labels[...idx], target_label: batch_labels[idx])
end

cycle_train(source_label: batch_labels, finalize: true)
