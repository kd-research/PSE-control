# frozen_string_literal: true

require 'active_record'

module ParameterObjectActions
  def initialize_database(force: false)
    connection.create_table :parameters, force: force do |t|
      t.string :file
      t.json :parameters, required: true
      t.string :split, default: 'train'
      t.string :state, default: 'raw'
    end
  end

  def establish_connection
    db_config = YAML.safe_load(File.open('config/database.yml'))
    ActiveRecord::Base.establish_connection(db_config)
  end
end

class ParameterObject < ActiveRecord::Base
  self.table_name = 'parameters'
  enum split: %i[train cross_valid test prediction]
  enum state: %i[raw processed]
  extend ParameterObjectActions

  def safe_set_parameter(parameters, length:)
    raise "Not an array" unless parameters.is_a? Array
    raise "Not an array of float" unless parameters.all? { |x| x.is_a? Float }
    raise "Amount incorrect" unless parameters.length == length
    self.parameters = parameters
  end
  def to_txt
    parameters.map(&:to_s).join(' ')
  end
end
