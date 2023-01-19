# frozen_string_literal: true

require 'tqdm'
require 'matrix'
require_relative '../lib/parameter_object'

def parse_matrix(filename)
  data = File.readlines(filename).map do |line|
    line.split.map { |x| (x.to_f+1) / 2 }
  end
  Matrix[*data]
end

ParameterObject.establish_connection
ParameterObject.delete_all

pd = parse_matrix('storage/pd.npy')
pd.row_vectors.tqdm(leave: true).map do |vec|
  pobj = ParameterObject.new(split: :prediction)
  pobj.safe_set_parameter(vec.to_a, length: 9)
  pobj.save!
end