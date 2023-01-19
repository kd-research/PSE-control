# frozen_string_literal: true

require 'matrix'
require_relative '../lib/parameter_object'
require_relative '../lib/parameter_object_relation'

ParameterObject.establish_connection
ParameterObjectRelation.delete_all

def parse_matrix(filename)
  data = File.readlines(filename).map do |line|
    line.split.map { |x| (x.to_f+1) / 2 }
  end
  Matrix[*data]
end

all_gt = parse_matrix('storage/gt.npy')
all_pd = parse_matrix('storage/pd.npy')

gt_error_counter = 0
all_gt.row_vectors.zip(all_pd.row_vectors).each do |gt, pd|
  gt_record = ParameterObject.find_by_parameter(gt, carefully: true)
  pd_record = ParameterObject.find_by_parameter(pd, carefully: true)
  raise "gt record not found" unless gt_record
  raise "pd record not found" unless pd_record
  ParameterObjectRelation.new do |o|
    o.from = gt_record
    o.to = pd_record
    o.relation = :prediction
  end.save!
rescue
  puts $!.message
  gt_error_counter += 1
  next
end
puts gt_error_counter