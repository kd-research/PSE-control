# frozen_string_literal: true

require 'erb'
require_relative '../storage_loader'

module AgentFormer
  ##
  # Get singleton renderer
  def self.renderer_instance
    @renderer_instance ||= AgentFormerConfigRenderer.new
  end

  ##
  # Class to render different agentformer configs
  class AgentFormerConfigRenderer
    attr_reader :result_dir

    def initialize
      orig_dir = StorageLoader.get_absolute_path(CONFIG['result_dir'])
      @result_dir = if File.exist?(orig_dir)
                      Snapshot.make_snapshot(orig_dir)
                    else
                      Snapshot.make_empty_snapshot(orig_dir)
                    end
    end

    ##
    # Agentformer dataset input specification
    def set_data_source(train_list, valid_list, test_list)
      @data_source = {
        'steersim_data_source' =>
          {
            'train_source' => train_list,
            'valid_source' => valid_list,
            'test_source' => test_list
          }
      }
    end

    ##
    # Render an yml page stored in config/extern
    def render(target)
      case
      when File.exist?("config/extern/#{target}.yml.erb")
        target = ERB.new(File.read("config/extern/#{target}.yml.erb"), trim_mode: '-')
        target.result(binding)
      when File.exist?("config/extern/#{target}.yml")
        File.read("config/extern/#{target}.yml")
      else
        raise StandardError, "No template #{target} found"
      end
    end

    def data_source?
      !!@data_source
    end

    def agent_former_extra
      SteerSuite.info.agent_former_config.to_yaml(UseHeader: false)
    rescue /No scene info set/
      ''
    end

    def include_data_source
      @data_source.to_yaml.delete_prefix("---\n")
    end

    def to_h
      YAML.safe_load(render('agentformer'))
    end

    def [](...)
      to_h.send(:[], ...)
    end
  end
end