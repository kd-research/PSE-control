require 'tqdm'

require_relative '../lib/steer_suite'
require_relative '../lib/parameter_record/parameter_object'
require_relative '../lib/parameter_record/parameter_object_relation'

$target = :default
ParameterObject.establish_connection(target: $target)
ParameterObject.initialize_database(force: true)
ParameterObjectRelation.initialize_database(force: true)

def save_pobj(fname, parameter, split, state)
  pobj = ParameterObject.new
  pobj.file = fname
  pobj.safe_set_parameter(parameter, length: 9)
  pobj.state = state
  pobj.split = split
  pobj.save!
end

def get_binary_filenames(dirname)
  Dir.glob("*.bin", base: dirname)
end

class Array
  def debug_sample
    if $target == :test
      self.take(100).tqdm(leave: true)
    else
      self.take(100).tqdm(leave: true)
    end
  end
end

dirname = '/home/kaidong/RubymineProjects/ActiveLoop/storage/steersimRecord-train'
get_binary_filenames(dirname).debug_sample.each do |fname|
  fullpath = File.join(dirname, fname)
  data = SteerSuite.load(fullpath, need_trajectory: false)
  save_pobj(fullpath, data.parameter, :train, :processed)
end

dirname = '/home/kaidong/RubymineProjects/ActiveLoop/storage/steersimRecord-cv'
get_binary_filenames(dirname).debug_sample.each do |fname|
  fullpath = File.join(dirname, fname)
  data = SteerSuite.load(fullpath, need_trajectory: false)
  save_pobj(fullpath, data.parameter, :cross_valid, :processed)
end
