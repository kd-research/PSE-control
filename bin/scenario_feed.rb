require 'tqdm'
require 'fileutils'

require_relative '../lib/steer_suite'
require_relative '../lib/parameter_record/parameter_object'
require_relative '../lib/parameter_record/parameter_object_relation'

$amount = 10000

ParameterDatabase.establish_connection(target: :tmp)
ParameterDatabase.initialize_database(force: true)

def get_binary_filenames(dirname)
  Dir.glob(File.join(dirname, "*.bin"))
end

%w[scene6].each do |scene|

  SteerSuite.reinitialize!

  SteerSuite.set_info(scene)
  steersuite_config = SteerSuite.get_config.dup
  steersuite_config['steersuite_record_pool'] = File.join(SteerSuite.info.data_location[:base], 'record')
  steersuite_config['steersuite_process_pool'] = File.join(SteerSuite.info.data_location[:base], 'process')

  SteerSuite.module_eval do
    remove_const(:CONFIG)
    const_set(:CONFIG, steersuite_config)
  end

  $amount.times.tqdm.each do
    pobj = ParameterObject.new(split: :train, state: :raw, label: 'budget-ground')
    pobj.safe_set_parameter(SteerSuite.info.parameter_size.times.map { rand })
    pobj.save!
  end

  SteerSuite.simulate_unsimulated
  SteerSuite.process_unprocessed

end