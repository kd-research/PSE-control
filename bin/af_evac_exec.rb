#!/usr/bin/env -S ruby -s -Ilib
require 'pry'
require 'tqdm'
require 'agent_former'
require 'steer_suite'
require 'active_learning'
require 'parameter_object'

$agent_num ||= "10"

abort "Must specify subdir in evac scenario" unless $subdir
SteerSuite.set_info("scene_evac_#{$scenenum}", subdir: $subdir)

ParameterDatabase.establish_connection
ParameterDatabase.initialize_database(force: true)

ParameterDatabase.load_from_directory(SteerSuite.info.data_location[:train20], split: :train, state: :valid_raw, label: 'budget-ground')
ParameterDatabase.load_from_directory(SteerSuite.info.data_location[:valid20], split: :cross_valid, state: :valid_raw, label: 'budget-ground')

train_files = ParameterObject.where(split: :train, state: :valid_raw, label: 'budget-ground').pluck(:file)
valid_files = ParameterObject.where(split: :cross_valid, state: :valid_raw, label: 'budget-ground').pluck(:file)

renderer = AgentFormer.renderer_instance
renderer.instance_variable_set :@segmented, '-evac'
renderer.instance_variable_set :@num_epochs, 2
renderer.instance_variable_set :@extra, "agent_num: #{$agent_num}\n"
renderer.set_data_source(train_files, valid_files, [])

AgentFormer.call_agentformer
AgentFormer.call_latent_dump
ActiveLearningCaller.keras_train(segmented: true)
ActiveLearningCaller.keras_sample_train(segmented: true)
