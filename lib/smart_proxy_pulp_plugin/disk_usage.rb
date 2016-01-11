module PulpProxy
  class DiskUsage
    include ::Proxy::Util
    SIZE = { :kilobyte => 1_024, :megabyte => 1_048_576, :gigabyte => 1_073_741_824, :terabyte => 1_099_511_627_776 }

    attr_reader :path, :stat, :size

    def initialize(opts ={})
      @path = opts[:path] || raise(::Proxy::Error::ConfigurationError, 'Unable to continue - must provide a path.')
      @size = SIZE[opts[:size]] || SIZE[:gigabyte]
      @stat = {}
      find_df
      get_stat
    end

    def to_json
      stat.to_json
    end

    private

    attr_reader :command_path

    def find_df
      @command_path = which('df') || raise(::Proxy::Error::ConfigurationError, 'df command was not found unable to retrieve usage information.')
    end

    def command
      "#{command_path} -B#{size} #{path}"
    end

    def get_stat
      raw = Open3::popen3(command) do |stdin, stdout, stderr, thread|
        stdout.read.split("\n")
      end

      titles = raw.shift.downcase.gsub('mounted on', 'mounted').split.map(&:to_sym)
      raw.each do |line|
        values = line.split
        mount_path = values[-1]
        @stat[mount_path] = [titles.zip(values)]
      end
    end
  end
end
