# frozen_string_literal: true

module SteerSuite
  class SteersimBinaryHandler # :nodoc:
    def initialize(file, data = nil)
      @file = file
      @data = data
    end

    def readsection(data_format)
      size = @file.read(4).unpack1('l')
      @file.read(size*4).unpack(data_format)
    end

    def writesection(data, data_format)
      size = data.size
      @file.write([size].pack('l'))
      @file.write(data.pack(data_format))
    end

    def readbin(need_trajectory: true)
      @file.seek(0)
      filename = (File.basename(@file.path, '.bin') if @file.respond_to?(:path))
      object_type = readsection('l*')
      object_info = readsection('f*')
      parameter = readsection('f*')

      agent_loc = []
      if need_trajectory
        agent_loc << readsection('f*') until @file.eof?
      end

      agent_data = agent_loc.map do |pos|
        traj = pos.each_slice(2).map {|x| Vector[*x]}
        Data::TrajectoryList.new(traj)
      end
      @file.flush

      @data = Data::SteersimBinary.new(filename, object_type, object_info, parameter, agent_data)
    end

    def writebin
      @file.seek(0)
      writesection(@data.object_type, 'l*')
      writesection(@data.object_info, 'f*')
      writesection(@data.parameter, 'f*')
      @data.agent_data.each do |t|
        writesection(t.rawdata, 'f*')
      end
      @file.flush
    rescue StandardError
      puts "incorrect input data #{@data.inspect}"
      raise
    end
  end
end
