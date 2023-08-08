#!/usr/bin/env -S ruby -s -Ilib
require 'tqdm'
require 'fileutils'

require 'steer_suite'
require 'parameter_record/parameter_object'
require 'parameter_record/parameter_object_relation'

$amount = $amount&.to_i || 16000
$try_amount = $try_amount&.to_i || 100

ParameterDatabase.establish_connection(target: :tmp)

def get_binary_filenames(dirname)
  Dir.glob(File.join(dirname, "*.bin"))
end

$scene.split(',').each do |scene|
  SteerSuite.reinitialize!

  SteerSuite.set_info(scene)
  steersuite_config = SteerSuite.get_config.dup
  steersuite_config['steersuite_record_pool'] = File.join(SteerSuite.info.data_location[:base], 'identity-record')
  if $noprocess
    steersuite_config['steersuite_process_pool'] = steersuite_config['steersuite_record_pool']
  else
    raise
    steersuite_config['steersuite_process_pool'] = File.join(SteerSuite.info.data_location[:base], 'process')
  end

  SteerSuite.module_eval do
    remove_const(:CONFIG)
    const_set(:CONFIG, steersuite_config)
  end

  until Dir["#{steersuite_config['steersuite_process_pool']}/*.bin"].size > $amount
    ParameterDatabase.initialize_database(force: true)
    def equal_rand(size: 25)
      Array.new(5) { rand } * size
    end
    $try_amount.times.tqdm.each do
      pobj = ParameterObject.new(split: :train, state: :raw, label: 'budget-ground')
      pobj.safe_set_parameter(
        [rand] + equal_rand(size:75)
      )
      pobj.save!
    end

    SteerSuite.simulate_unsimulated
    SteerSuite.process_unprocessed unless $noprocess
  end

end