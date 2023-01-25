require 'yaml'
require_relative '../lib/agent_former'
require_relative '../lib/parameter_object'
require_relative '../lib/steer_suite'

$VERBOSE = 0

ParameterObject.establish_connection
train_binaries = ParameterObject.train.pluck(:file)
valid_binaries = ParameterObject.cross_valid.pluck(:file)
test_binaries = []

renderer = AgentFormer.renderer_instance
renderer.set_data_source(train_binaries, valid_binaries, test_binaries)

#AgentFormer.call_agentformer(renderer)
AgentFormer.call_latent_dump
#AgentFormer.call_env_predict

