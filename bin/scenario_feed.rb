#!/usr/bin/env -S ruby -s -Ilib
require 'bundler/setup'
require 'tqdm'
require 'fileutils'

require 'steer_suite'
require 'parameter_record/parameter_object'
require 'parameter_record/parameter_object_relation'

$amount = $amount&.to_i || 750  # train 400 + valid 150 + test 200
$try_amount = $try_amount&.to_i || 900

# @param scene [String] name of the scene, used to identify the scene in config file
# @param subdir [String] subdirectory of the scene
# @yield [] block that returns a array of parameters
# typical scene name and parameter length:
#  scene_evac_sf_1: 1
#  scene_evac_sf_[2-14]: 75
#  scene_evac_orca_1: 1
#  scene_evac_orca_[2-6]: 75
#  scene_evac_cog_1: 1
#  scene_evac_cog_[2-11]: 75
def feed_scene(scene, subdir: nil)
  SteerSuite.reinitialize!

  SteerSuite.set_info(scene, subdir: subdir)
  steersuite_config = SteerSuite.get_config.dup
  steersuite_config['steersuite_record_pool'] = SteerSuite.info.data_location[:base]
  steersuite_config.delete('steersuite_process_pool')

  FileUtils::mkdir_p(steersuite_config['steersuite_record_pool'])
  dbname = "metadata.sqlite3"
  dbpath = File.expand_path File.join(steersuite_config['steersuite_record_pool'], dbname)

  ActiveRecord::Base.clear_all_connections! if ActiveRecord::Base.connected?
  ParameterDatabase.establish_connection(target: :tmp, database: dbpath)
  ParameterDatabase.initialize_database

  SteerSuite.module_eval do
    remove_const(:CONFIG)
    const_set(:CONFIG, steersuite_config)
  end

  until Dir["#{steersuite_config['steersuite_record_pool']}/*.bin"].size >= $amount
    $try_amount.times.tqdm.each do
      pobj = ParameterObject.new(split: :train, state: :raw, label: 'budget-ground')
      pobj.safe_set_parameter( yield )
      pobj.save!
    end

    SteerSuite.simulate_unsimulated
  end

  SteerSuite.validate_raw(remove: true)
end

begin
  (2..11).each do |i|
    feed_scene("scene_evac_cog_#{i}", subdir: 'homogeneous') do
      [rand] * 75
    end

    feed_scene("scene_evac_cog_#{i}", subdir: 'heterogeneous') do
      Array.new(75) { rand }
    end
  end
end
