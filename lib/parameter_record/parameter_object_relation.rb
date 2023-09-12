# frozen_string_literal: true

module ParameterObjectRelationActions
  def initialize_database(force: false)
    connection.create_table :parameter_relations, force: force do |t|
      t.belongs_to :from, class_name: "ParameterObject"
      t.belongs_to :to, class_name: "ParameterObject"
      t.string :relation, set_info: "relation_nil"
    end
  end
end

class ParameterObjectRelation < ActiveRecord::Base
  after_destroy :destroy_tos
  self.table_name = "parameter_relations"

  ALL_RELATION = %w[relation_nil prediction augmentation process].freeze
  enum relation: ALL_RELATION.zip(ALL_RELATION).to_h
  belongs_to :from, class_name: "ParameterObject"
  belongs_to :to, class_name: "ParameterObject"

  extend ParameterObjectRelationActions

  private

  def destroy_tos
    to.destroy
  end
end
