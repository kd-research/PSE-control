require_relative '../lib/parameter_object'
require_relative '../lib/parameter_object_relation'
require_relative '../lib/rplot'

ParameterObject.establish_connection
ParameterObjectRelation.prediction.each.with_index do |rel, i|
  truth = rel.from.as_scenario_obj
  pred = rel.to.as_scenario_obj
  next unless truth && pred
  p = RPlot::PlotExecutor.new
  p.plot_scenarios([truth, pred], as: %w[truth prediction])
  p.noninteractive
  p.save_png(File.join(Dir.home, "compare_imgs", "compare#{i}.png"))
  p.execute
end

Process.waitall