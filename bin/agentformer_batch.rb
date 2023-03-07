require 'yaml'
require 'tqdm'
require 'pathname'
require 'fileutils'
require_relative '../lib/active_learning/active_learning_caller'
require_relative '../lib/storage_loader'
require_relative '../lib/agent_former'
require_relative '../lib/steer_suite'
require_relative '../lib/parameter_object'

ParameterObject.establish_connection

# Establish connection and reset the database
# Initialize database with random 500 training samples

def cycle_train(source_label, num_sample)
  train_files = ParameterObject.where(split: :train, state: :processed, label: source_label).limit(num_sample).pluck(:file)
  valid_files = ParameterObject.where(split: :cross_valid, state: :processed, label: 'budget-ground').pluck(:file)
  test_files = []

  renderer = AgentFormer.renderer_instance
  renderer.instance_variable_set :@model_suffix, sprintf('%06d', num_sample)
  renderer.set_data_source(train_files, valid_files, test_files)
  start_time = Time.now
  AgentFormer.call_agentformer(renderer)
  puts "Agentformer #{num_sample} training use #{Time.now - start_time} seconds"

  start_time = Time.now
  AgentFormer.call_latent_dump
  puts "Agentformer #{num_sample} latent dump use #{Time.now - start_time} seconds"

  start_time = Time.now
  ActiveLearningCaller.keras_train
  puts "Agentformer #{num_sample} keras train use #{Time.now - start_time} seconds"

end

source_label = 'budget-ground'
sample_nums = (2000..4000).step(500)
sample_nums.each { |s| cycle_train(source_label, s) }
