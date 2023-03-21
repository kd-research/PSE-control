# frozen_string_literal: true

module ParameterObjectActions
  def initialize_database(force: false)
    connection.create_table :parameters, force: force do |t|
      t.json :parameters, required: true
      t.string :p_hash, index: true
      t.string :file
      t.string :label 
      t.string :split, :state
      t.boolean :active_generated, default: false
    end
  end

  # <b>DEPRECATED:</b> Please use <tt>ParameterDatabase.establish_connection</tt> instead.
  def establish_connection(...)
    warn '[DEPRECATION] `ParameterObject.establish_connection` is deprecated.'\
      ' Please use `ParameterDatabase.establish_connection` instead.'
    ParameterDatabase.establish_connection(...)
  end
end

##
# Record object that contains parameters
# attributes:
#   parameters, file,
class ParameterObject < ActiveRecord::Base
  self.table_name = 'parameters'

  ALL_SPLIT = %w[split_nil train cross_valid test prediction active_train].freeze
  enum split: ALL_SPLIT.zip(ALL_SPLIT).to_h
  ALL_STATE = %w[state_nil raw processed rot].freeze
  enum state: ALL_STATE.zip(ALL_STATE).to_h

  has_one :benchmark, class_name: 'BenchmarkLogs'
  has_one :as_predictee_relation, -> { where(relation: :prediction) },
          class_name: 'ParameterObjectRelation', foreign_key: :to_id
  has_one :predicted_from, through: :as_predictee_relation, source: :from

  has_many :as_predictor_relation, -> { where(relation: :prediction) },
           class_name: 'ParameterObjectRelation', foreign_key: :from_id
  has_many :predicted_as, through: :as_predictor_relation, source: :to

  has_one :as_processee_relation, -> { where(relation: :process) },
          class_name: 'ParameterObjectRelation', foreign_key: :to_id
  has_one :processed_from, through: :as_processee_relation, source: :from

  has_many :as_processor_relation, -> { where(relation: :process) },
           class_name: 'ParameterObjectRelation', foreign_key: :from_id
  has_many :processed_in, through: :as_processor_relation, source: :to

  scope :with_no_simulation, -> { where(file: nil).or(where(file: '')) }

  extend ParameterObjectActions

  def rehash!
    self.p_hash = self.class.parameter_hash_func(self.parameters)
  end

  def safe_set_parameter(parameters, length: nil)
    raise 'Not an array' unless parameters.is_a? Array
    raise 'Not an array of float' unless parameters.all? { |x| x.is_a? Float }
    raise 'Amount incorrect' unless length.nil? || parameters.length == length

    self.parameters = parameters
    rehash!
  end

  ##
  # Steersuite object is a raw data object read from
  # steersim binaries
  def as_steersuite_obj
    return nil unless file && File.exist?(file)

    SteerSuite.load(file)
  end

  ##
  # Scenario object is a higher level scenario processor
  # support easy scenario modifications
  def as_scenario_obj
    return nil unless file && File.exist?(file)

    SteerSuite::Scenario.from_file(file)
  end

  # Get string representation of parameters that can be useful in steersim calling
  # @return [String]
  def to_txt
    parameters.map(&:to_s).join(' ')
  end

  def self.find_by_parameter(parameters, carefully: true, verbose: false)
    p_hash = parameter_hash_func(parameters)
    result = ParameterObject.where(p_hash: p_hash)
    return result.first unless carefully && result.empty?

    result = find_by_parameter_slow(parameters)
    if result && verbose
      puts 'hash failed but find result'
      puts "find target: #{parameters.join(',')}"
      puts "target hash: #{parameter_hash_func(parameters)}"
      puts "found: #{result.join(',')}"
      puts "found hash: #{parameter_hash_func(result)}"
    end
    ParameterObject.where(p_hash: parameter_hash_func(result)).first
  end

  def self.find_by_parameter_slow(parameters)
    target_vec = Vector[*parameters.to_a]
    candidate = ParameterObject.pluck(:parameters).map do |p|
      Vector[*p]
    end.min_by { |v| (v - target_vec).r }
    (candidate - target_vec).r < 1e-6 ? candidate : nil
  end

  def self.parameter_hash_func(parameters)
    stable_parameters = parameters.to_a.map { |x| x.round(5).floor(4) }
    Digest::SHA1.hexdigest(stable_parameters.join)
  end
end
