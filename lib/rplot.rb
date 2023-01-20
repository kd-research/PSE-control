require 'erb'
require 'csv'
require 'tempfile'

module RPlot
  PlotActionInfo = Struct.new(:show, :save_plot, :csv_name, :png_name, :timeout, keyword_init: true)
  PlotActionInfo.class_eval do
    def get_binding
      binding
    end
  end

  module RScriptTemplate
    # A trajectory template requires a csv with four columns
    # x, y are coordinates of trajectories
    # aid is a unique id for each agent
    # gid is a unique id for each color group, usually classified by scenario
    def self.plot_trajectory_template
      ERB.new <<~RSCRIPT, trim_mode: '<>'
        library('ggplot2')
        <% if save_plot && !show %>
        png(filename = '<%= png_name %>')
        <% elsif show %>
        x11() 
        <% end %>
        data = read.csv("<%= csv_name %>")
        p = ggplot(data, aes(x, y, group=aid, colour=gid)) 
        p = p + geom_path(arrow=arrow(angle=5, type='closed'))
        p + coord_fixed()
        <% if save_plot && !show %>
        suppress <- dev.off()
        <% elsif save_plot %>
        savePlot('<%= png_name %>')
        <% end %>
        <% if show %>
        Sys.sleep(<%= timeout %>)
        <% end %>
      RSCRIPT
    end
  end

  class PlotExecutor
    class_variable_set(:@@plot_pool, [])
    def initialize(opts = {})
      opts = { show: true, timeout: 10 }.merge(opts)
      @plot_action = PlotActionInfo.new(opts)
      @global_aid = Enumerator.produce('a', &:succ)
      @global_gid = Enumerator.produce('a', &:succ)
      @target_script_template = nil
      @@plot_pool << self
    end

    def get_rscript
      @target_script_template&.result(@plot_action.get_binding)
    end

    ##
    # when this is called, all action previous set will be executed
    def execute
      script = @target_script_template.result(@plot_action.get_binding)
      fork do
        plot_obj = [self]  # prevent object from gc during fork
        open('|Rscript -', 'w') do |io|
          io.puts script
        end
        Kernel.exit!($?.exitstatus)
      end
    end

    ##
    # take a list of scenario and make a trajectory plot
    def plot_scenarios(scenario_list, as: :auto)
      temp_csv do
        aids = Enumerator.produce('a', &:succ)
        gids = if as == :auto
                 @global_gid
               else
                 as
               end
        scenario_list.zip(gids).each do |scenario, gid|
          scenario.map_trajectory.each do |trajectory|
            fill_trajectory(trajectory, aids.next, gid)
          end
        end
      end

      @target_script_template = RScriptTemplate.plot_trajectory_template
      self
    end

    def save_png(filename)
      @plot_action.save_plot = true
      @plot_action.png_name = filename
    end

    def interactive(timeout = 10)
      @plot_action.show = true
      @plot_action.timeout = timeout
    end

    def noninteractive
      @plot_action.show = false
      @plot_action.timeout = 0
    end

    private

    def temp_csv
      @file = Tempfile.new(%w[trajectory. .csv])
      @plot_action.csv_name = @file.path
      @csv = CSV.new(@file)
      @csv << %w[x y aid gid]
      yield
      @csv.close
    end

    def fill_trajectory(trajectory, aid, gid)
      trajectory.map_frame do |vec|
        @csv << [vec[0], vec[1], aid, gid]
      end
    end
  end


end
