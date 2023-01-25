# frozen_string_literal: true

require 'minitest/autorun'
require 'ostruct'
require_relative '../lib/steer_suite'

class SteersimWorkerTest < Minitest::Test
  def test_steersim_worker_dry_run
    pobj = OpenStruct.new(parameters: (1..9))
    SteerSuite.simulate(pobj, dry_run: true)
  end
end
