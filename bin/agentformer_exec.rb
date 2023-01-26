require 'yaml'
require 'pathname'
require_relative '../lib/storage_loader'
require_relative '../lib/agent_former'
require_relative '../lib/parameter_object'
require_relative '../lib/steer_suite'

$VERBOSE = 0

def change_path(path_old)
  p = Pathname.new(path_old)
  prel = p.relative_path_from(StorageLoader::STORAGE_BASE)
  File.join('/home/hpc/hpcguest4/storage', prel)
end

ParameterObject.establish_connection
train_binaries = ParameterObject.train.pluck(:file).map(&method(:change_path)).sample(4500)
valid_binaries = ParameterObject.cross_valid.pluck(:file).map(&method(:change_path))
test_binaries = []

StorageLoader.storage_base = '/home/hpc/hpcguest4/storage'
renderer = AgentFormer.renderer_instance
renderer.set_data_source(train_binaries, valid_binaries, test_binaries)
renderer.instance_eval { @model_suffix = "_#{train_binaries.size}"}

cmd, cfg = AgentFormer.call_agentformer(renderer, load: :disabled, dry_run: true)
puts cmd.shelljoin
File.write("tempcfg-#{train_binaries.size}.yml", cfg)
#AgentFormer.call_latent_dump
#AgentFormer.call_env_predict

