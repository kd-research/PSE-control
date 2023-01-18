# frozen_string_literal: true

require 'matrix'
require_relative '../lib/parameter_object'

def parse_matrix(filename)
  data = File.readlines(filename).map do |line|
    line.split.map &:to_f
  end
  Matrix[*data]
end

ParameterObject.establish_connection

pd = parse_matrix('pd.npy')
pd.row_vectors.map do |vec|
  pobj = ParameterObject.new(split: :prediction)
  pobj.safe_set_parameter(vec.to_a, length: 9)
  pobj.save!
end