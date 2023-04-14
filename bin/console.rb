# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
$NOINIT = true

require 'parameter_object'
require 'steer_suite'
require 'agent_former'
require 'active_learning'

$NOINIT = nil

require 'pry'

Pry.start
