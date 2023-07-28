#!/usr/bin/env -S ruby -s -Ilib
require 'pry'
require 'tqdm'
require 'agent_former'
require 'steer_suite'
require 'active_learning'
require 'parameter_object'

$agent_num ||= "10"

ParameterDatabase.establish_connection
ParameterDatabase.initialize_database(force: true)

SteerSuite.set_info('scene_evac_1')

def get_binary_filenames(dirname)
  Dir.glob("#{dirname}/*.bin")
end

train_records = get_binary_filenames(SteerSuite.info.data_location[:train20])
train_records.tqdm.each do |fname|
  pobj = ParameterObject.new(split: :train, state: :raw, label: 'budget-ground')
  SteerSuite.document(pobj, fname)
  pobj.save!
end
print("\r\n")

valid_records = get_binary_filenames(SteerSuite.info.data_location[:valid20])
valid_records.tqdm.each do |fname|
  pobj = ParameterObject.new(split: :cross_valid, state: :raw, label: 'budget-ground')
  SteerSuite.document(pobj, fname)
  pobj.save!
end
print("\r\n")

SteerSuite.mark_valid!


train_files = ParameterObject.where(split: :train, state: :valid_raw, label: 'budget-ground').pluck(:file)
valid_files = ParameterObject.where(split: :cross_valid, state: :valid_raw, label: 'budget-ground').pluck(:file)

renderer = AgentFormer.renderer_instance
renderer.instance_variable_set :@segmented, '-evac'
renderer.instance_variable_set :@num_epochs, 10
renderer.instance_variable_set :@extra, "agent_num: #{$agent_num}\n"
renderer.set_data_source(train_files, valid_files, [])

#AgentFormer.call_agentformer
AgentFormer.call_latent_dump
ActiveLearningCaller.keras_train(segmented: true)
ActiveLearningCaller.keras_sample_train(segmented: true)
