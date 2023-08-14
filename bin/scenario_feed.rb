#!/usr/bin/env -S ruby -s -Ilib
require 'tqdm'
require 'fileutils'

require 'steer_suite'
require 'parameter_record/parameter_object'
require 'parameter_record/parameter_object_relation'

$amount = $amount&.to_i || 16000
$try_amount = $try_amount&.to_i || 100

ParameterDatabase.establish_connection(target: :tmp)
ParameterDatabase.initialize_database(force: true)
SteerSuite.set_info('scene_evac_3', subdir: 'identity-record')

scenes = [3, 4, 5, 6, 7].map { |i| "scene_evac_#{i}" }
type = %w[identity-record ordered-3738-record mixed-3738-record fullrandom-record]

def get_parameter_generator(t, pa: 5)
  arand = proc { Array.new(pa) { rand } }
  type_block = {
    'identity-record' => ->() { [rand] + arand[] * 75 },
    'ordered-3738-record' => ->() { [rand] + arand[] * 37 + arand[] * 38 },
    'mixed-3738-record' => ->() { [rand] + arand[].chain(arand[]).cycle.take(75 * pa)  },
    'fullrandom-record' => ->() { [rand] + Array.new(75 * pa) { rand } }
  }
  type_block[t]
end

def feed_scene(scene, subdir: nil)
  SteerSuite.reinitialize!

  SteerSuite.set_info(scene, subdir: subdir)
  steersuite_config = SteerSuite.get_config.dup
  steersuite_config['steersuite_record_pool'] = SteerSuite.info.data_location[:base]
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
    $try_amount.times.tqdm.each do
      pobj = ParameterObject.new(split: :train, state: :raw, label: 'budget-ground')
      pobj.safe_set_parameter( yield )
      pobj.save!
    end

    SteerSuite.simulate_unsimulated
    SteerSuite.process_unprocessed unless $noprocess
  end

  SteerSuite.validate_raw(remove: true)
end

type.each do |t|
  type_block = get_parameter_generator(t, pa: 5)
  feed_scene('scene_evac_1', subdir: t, &type_block)

  scenes.each do |scene|
    type_block = get_parameter_generator(t, pa: 1)
    feed_scene(scene, subdir: t, &type_block)
  end
end
