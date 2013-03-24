require 'fluent/load'
require 'fluent-top/version'

require 'hirb'

module Fluent::Top
  class CLI
    def initialize(options)
      @interval = options[:interval] || 1.0
      @endpoint = options[:endpoint] || '0.0.0.0:24230'
      @fluentd = setup_agent
      @width, @height = detect_terminal_size
    end

    def run
      loop {
        display
        sleep @interval
      }
    rescue Interrupt
    end

    OUTPUT_FIELDS = [:match, :type, :emit_count, :num_queue, :num_buffer_keys, :total_chunk_size]
    INSTANCE_FIELDS = [:num_match_caches, :num_threads] + GC.stat.keys.sort
    SYSTEM_FIELDS = [:cpu, :rss, :vsize] # TODO: make this columns user-definable

    def display
      out = []
      num_lines = 0

      out << "Fluentd daemon: #{@endpoint}"
      #out << "Update interval: #{@interval} sec"
      out << ""
      num_lines += 2

      output_info = @fluentd.output_info.map { |info|
        info[:match] = info[:match][2..-3] # Remove \A and \Z
        info
      }
      out << "Outputs:"
      out << ""
      out << render(output_info, OUTPUT_FIELDS)
      num_lines += output_info.size * 2 + 3

      instance_info = @fluentd.instance_info
      instance_info.merge!(instance_info.delete(:gc_stat))

      out << ""
      out << "Instance:"
      out << ""
      out << render([instance_info], INSTANCE_FIELDS)
      num_lines += 1 + 3

      out << ""
      out << "System:"
      out << ""
      out << render([parse_system_info(@fluentd.system_info)], SYSTEM_FIELDS)
      num_lines += 3

      (@height - out.size - num_lines).times { out << "" }
      out << "(Ctrl-c to quit.)"

      clear
      puts out.join("\n")
    end

    private

    def render(rows, fields)
      Hirb::Helpers::Table.render(rows, :fields => fields, :description => false, :max_width => @width)
    end

    def parse_system_info(lines)
      columns = lines.strip.split("\n").last.split
      Hash[*SYSTEM_FIELDS.zip(columns).flatten]
    end

    def clear
      print "\033[2J"
    end

    def command_exists?(command)
      ENV['PATH'].split(File::PATH_SEPARATOR).any? { |d| File.exists? File.join(d, command) }
    end

    def setup_agent
      require 'drb/drb'

      uri = if @endpoint.start_with?('/')
              "drbunix:#{@endpoint}"
            else
              "druby://#{@endpoint}"
            end

      remote_engine = DRb::DRbObject.new_with_uri(uri)
      class << remote_engine
        undef_method :instance_eval
      end

      remote_engine.instance_eval(<<'EOS'
  self.class.send(:define_method, :output_info, Proc.new {
    @matches.map { |m|
      result = {
        :type => m.output.class.name,
        :match => m.instance_variable_get(:@pattern).instance_variable_get(:@regex).source
      }

      o = m.output
      if o.kind_of?(Fluent::BufferedOutput)
        result[:emit_count] = o.instance_variable_get(:@emit_count)

        b = o.instance_variable_get(:@buffer)
        result[:num_queue] = b.queue_size
        result[:num_buffer_keys] = b.keys.size
        result[:total_chunk_size] = b.instance_variable_get(:@map).values.reduce(0) { |sum, q| sum + q.size }
      end

      result
    }
  })

  self.class.send(:define_method, :instance_info, Proc.new {
    { 
      :num_match_caches => @match_cache.size,
      :num_threads => Thread.list.size,
      :gc_stat => GC.stat
    }
  })

  self.class.send(:define_method, :system_info, Proc.new {
    `ps -o cpu,rss,vsize= -p #{Process.pid}`
  })
EOS
)
      remote_engine
    end

    # https://github.com/cldwalker/hirb/blob/master/lib/hirb/util.rb#L61-71
    def detect_terminal_size
      if (ENV['COLUMNS'] =~ /^\d+$/) && (ENV['LINES'] =~ /^\d+$/)
        [ENV['COLUMNS'].to_i, ENV['LINES'].to_i]
      elsif (RUBY_PLATFORM =~ /java/ || (!STDIN.tty? && ENV['TERM'])) && command_exists?('tput')
        [`tput cols`.to_i, `tput lines`.to_i]
      elsif STDIN.tty? && command_exists?('stty')
        `stty size`.scan(/\d+/).map { |s| s.to_i }.reverse
      else
        nil
      end
    rescue Exception => e
      nil
    end
  end
end
