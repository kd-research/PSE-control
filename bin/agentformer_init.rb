require 'tqdm'
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
