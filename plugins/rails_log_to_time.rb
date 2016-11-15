require 'json'

module Fluent
  class TextParser
    class RailsLogToTimeParser < Parser
      @@cached_time = [Time.now.to_f, Time.now.strftime('%Y-%m-%dT%H:%M:%S.%N')]
      Plugin.register_parser('rails_log_to_time', self)

      config_param :time_format, :string, default: nil # time_format is configurable

      def configure(conf)
        super
        @time_parser = TimeParser.new(@time_format)
      end

      # This is the main method. The input is the unit of data to be parsed.
      # If this is the in_tail plugin, it would be a line. If this is for in_syslog,
      # it is a single syslog message.
      def parse(input)
        output = /(\d{4})-(\d{2})-(\d{2})( |T)*(\d{2}):(\d{2}):(\d{2}).(\d{3,})/.match(input).to_s
        output = output.tr(' ', 'T')
        # Here is some workaroud to avoid log cannot be parsed.
        # So we cached parsed time as time of log cannot be parsed.
        if !output.nil? && output.strip != ''
          # If log can be pased, yield time of log and cached it in @@cached_time
          time = @time_parser.parse(output)
          @@cached_time = [time, output]
          yield time, output
        else
          # Increate cached time 1 millisecond
          # and set it as current log time.
          time = Time.parse @@cached_time[1]
          tmp = time.to_f
          tmp += 0.001
          @@cached_time[1] = Time.at(tmp).strftime('%Y-%m-%dT%H:%M:%S.%N')
          yield @@cached_time
        end
      rescue
        yield input
      end
    end
  end
end
