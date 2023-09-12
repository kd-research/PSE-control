# frozen_string_literal: true

require_relative "agent_former/agent_former_config_renderer"
require_relative "agent_former/agent_former"

module AgentFormer # :nodoc:
  extend ConfigLoader
  def self.reinitialize!
    @renderer_instance = nil

    remove_const :CONFIG if const_defined? :CONFIG
    remove_const :PROJECT_BASE if const_defined? :PROJECT_BASE
    const_set :CONFIG, load_config("config/agentformer.yml")
    const_set :PROJECT_BASE, Snapshot.make_snapshot(CONFIG["agent_former_base"])
    private_constant :CONFIG, :PROJECT_BASE
  end

  reinitialize!
end
