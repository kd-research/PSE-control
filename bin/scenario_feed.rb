require 'tqdm'

require_relative '../lib/steer_suite'
require_relative '../lib/parameter_record/parameter_object'
require_relative '../lib/parameter_record/parameter_object_relation'

$target = :default
ParameterDatabase.establish_connection(target: $target)
#ParameterDatabase.initialize_database(force: true)

if true
  10000.times.tqdm.each do |i|
    p = ParameterObject.new(label: 'budget-ground', split: :train, state: :raw, file: nil)
    p.safe_set_parameter(21.times.map { rand })
    p.save!
  end
end

SteerSuite.simulate_unsimulated
SteerSuite.process_unprocessed