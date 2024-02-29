#!/usr/bin/env -S ruby -Ilib

require 'bundler/setup'

require 'active_learning'
require 'agent_former'
require 'descriptive_statistics'
require 'json'
require 'optparse'
require 'parallel'
require 'parameter_record/parameter_object'
require 'parameter_record/parameter_object_relation'
require 'snapshot'
require 'steer_suite'
require 'storage_loader'
require 'yaml'


ExperimentContext = Struct.new(:gounds_location, 
                               :ground_type,
                               :predict_location,
                               :scene_name,
                               :sub_scene_name)

def make_json_prediction
  config = ActiveLearningCaller.const_get(:CONFIG)
  command_work_dir = config['active_learning_keras_base']
  singularity_container = config['singularity_container']
  singularity_command = "singularity exec --nv #{singularity_container} python3"

  Dir.chdir(command_work_dir) do
    command = ["#{singularity_command} predict_scene.py"]
    command << "-A" if $ablation
    command << "-i #{$input_json}"
    command << "-C #{$latent_location}"
    if $ablation
      command << "-o ablation.json"
    else
      command << "-o predict.json"
    end

    system(command.join(' '))
  end
end

def read_json_file(file_stream)
  file_stream.each_line.map do |line|
    JSON.parse(line)
  end
end

def ground_truth_file_location(id, context)
  ground_type_dir = case context.ground_type
                    when :train
                      'train-20fps'
                    when :cross_valid
                      'valid-20fps'
                    else
                      raise "Unknown ground type #{context.ground_type}"
                    end

  File.join(context.gounds_location,
            context.scene_name.tr('_', '-') + '-base-data',
            context.sub_scene_name + '-record',
            ground_type_dir,
            "#{id}.bin").tap do |filepath|
              raise "File not found #{filepath}" unless File.exist?(filepath)
            end
end

def loads_prediction_data_pair(data, context)
  SteerSuite.reinitialize!

  SteerSuite.set_info(context.scene_name, subdir: context.sub_scene_name)
  data.map do |datum|
    gt_filepath = ground_truth_file_location(datum['s'], context)
    gt_object = ParameterObject.new(split: context.ground_type,
                                    state: :processed,
                                    label: :ground)
    SteerSuite.document(gt_object, gt_filepath)
    gt_object.save!
    pred_object = ParameterObject.new(split: :prediction,
                                      state: :raw,
                                      label: :prediction)

    pred_object.safe_set_parameter(datum['p'])
    pred_object.predicted_from = gt_object
    pred_object.save!
  end

  SteerSuite.set_info(context.scene_name, subdir: context.sub_scene_name + '_prediction')
  SteerSuite.simulate_unsimulated
end

def compute_mae(from, to)
  config = AgentFormer.const_get(:CONFIG)
  singularity_container = config['singularity_container']
  command_base = config['agent_former_base']
  command_script = "./bin/compute_mae.py"
  singularity_command = "singularity exec --nv #{singularity_container} python3 #{command_script}"

  Dir.chdir(command_base) do
    command = "#{singularity_command} #{from} #{to}"
    result = `#{command}`
    result[/MAE:\s+(\d+\.\d+)/, 1].to_f
  end
end

$context = ExperimentContext.new(StorageLoader::STORAGE_BASE, :cross_valid, '.', nil, nil)
stages = %w[]

OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options] <Latent directory>"

  opts.on('-i', '--input=filename', 'json file that would be used as input') do |v|
    $input_json = v
  end

  opts.on('-t', '--scene-type=Type', 'type of simulation scene') do |v|
    $context.scene_name = v
  end

  opts.on('-s', '--subscene-type=Type', 'type of subscene') do |v|
    $context.sub_scene_name = v
  end

  opts.on('-j', '--scene-job-name=Type', 'scene identifier by job name') do |v|
    # sample jobname: orca_1-identity-record-evac10-rep0
    # scene name: scene_evac_orca_1
    # subscene name: identity-rep0

    scene_name, sub_scene_name = v.split('-', 2)
    $context.scene_name = "scene_evac_#{scene_name}"
    $context.sub_scene_name = sub_scene_name.gsub('record-evac10-', '')
  end

  opts.on('-A', '--ablation', 'Ablation examination') do
    $ablation = true
  end

  opts.on('--stage1', 'prediction environment from raw trajectories') do
    stages << :stage0
  end

  opts.on('--stage1', 'prediction environment from json') do
    stages << :stage1
  end

  opts.on('--stage2', 'prediction environment from ') do
    stages << :stage2
  end

  opts.on('--stage3', 'prediction environment from ') do
    stages << :stage3
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

$latent_location = ARGV.shift
raise 'Latent location not specified' unless $latent_location

database_path = if $ablation
                  File.join($latent_location, 'ablation.db')
                else
                  File.join($latent_location, 'predict.db')
                end

ParameterDatabase.establish_connection(database: database_path, copy: true)

def stage0
  files = ParameterObject.where(label: :raw).pluck(:file)
  renderer = AgentFormer.renderer_instance
  renderer.instance_variable_set :@segmented, '-evac'
  renderer.instance_variable_set :@num_epochs, 2
  renderer.instance_variable_set :@extra, "agent_num: #{$agent_num}\n"
  renderer.set_data_source(train_files, valid_files, [])

  AgentFormer.call_latent_dump
end

def stage1
  make_json_prediction
end

def stage2
  pred_json_location = if $ablation
                         File.join($latent_location, 'ablation.json')
                       else
                         File.join($latent_location, 'predict.json')
                       end
  pred_data = read_json_file(File.open(pred_json_location))
  loads_prediction_data_pair(pred_data, $context)
end

def stage3
  mae_list = Parallel.map(ParameterObjectRelation.all, progress: "relation") do |relation|
    from = relation.from.file
    to = relation.to.file
    raise "from file not found: #{from}" unless File.exist?(from)
    raise "to file not found: #{to}" unless File.exist?(to)
    mae = compute_mae(from, to)
  end

  puts mae_list.descriptive_statistics.stringify_keys.to_yaml
end

stages = %i[stage1 stage2 stage3] if stages.empty?
stages.each do |stage|
  send(stage)
end
