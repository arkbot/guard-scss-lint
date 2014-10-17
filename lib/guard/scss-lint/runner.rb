# coding: utf-8

require 'json'

module Guard
  class ScssLint
    # This class runs `scss-lint` command, retrieves result and notifies. An
    # instance of this class is intended to invoke `scss-lint` only once in
    # its lifetime.
    class Runner
      def initialize(options)
        @options = options
      end

      def run(paths = [])
        command = build_command(paths)
        passed = system(*command)
        handle_notifications(passed)
        passed
      end

      def handle_notifications(passed)
        case @options[:notification]
          when :failed
            notify(passed) unless passed
          when true
            notify(passed)
        end
      end

      def build_command(paths)
        command = build_formatters_for_command(['scss-lint'])
        command.concat(args_specified_by_user)
        command.concat(paths)
      end

      def build_formatters_for_command(command)
        # Keep default formatter for console.
        unless include_formatter_for_console?(args_specified_by_user)
          command.concat(%w(--format Default))
        end

        command.concat(['--format', 'JSON', '--out', json_file_path])
        command << '--force-exclusion'
      end

      def args_specified_by_user(args = @options[:cli])
        @args_specified_by_user ||= begin
          case args
            when Array, String then handle_args_array_or_string(args)
            when NilClass then []
            else fail ':cli option must be either an array or string'
          end
        end
      end

      def handle_args_array_or_string(args)
        args.is_a?(Array) ? args : args.shellsplit
      end

      def include_formatter_for_console?(cli_args)
        return true if @options[:hide_stdout]

        formatter_args(cli_args).each_value.any? do |args|
          args.none? { |a| a == '--out' || a.start_with?('-o') }
        end
      end

      def formatter_args(cli_args)
        index = -1
        args = cli_args.group_by do |arg|
          index += 1 if arg == '--format' || arg.start_with?('-f')
          index
        end
        args.delete(-1)
        args
      end

      def json_file_path
        @json_file_path ||= begin
          # Just generate random tempfile path.
          basename = self.class.name.downcase.gsub('::', '_')
          tempfile = Tempfile.new(basename)
          tempfile.close
          tempfile.path
        end
      end

      def result
        @result ||= begin
          File.open(json_file_path) do |file|
            # Rubinius 2.0.0.rc1 does not support `JSON.load` with 3 args.
            JSON.parse(file.read, symbolize_names: true)
          end
        end
      end

      def notify(passed)
        image = passed ? :success : :failed
        Notifier.notify(summary_text, title: 'scss-lint results', image: image)
      end

      def summary_text
        summary = result[:summary]

        text = pluralize(summary[:inspected_file_count], 'file')
        text << ' inspected, '

        offense_count = summary[:offense_count] || summary[:offence_count]
        text << pluralize(offense_count, 'offense', no_for_zero: true)
        text << ' detected'
      end

      def failed_paths
        failed_files = result[:files].reject do |file|
          offenses = file[:offenses] || file[:offences]
          offenses.empty?
        end
        failed_files.map do |file|
          file[:path]
        end
      end

      def pluralize(number, thing, options = {})
        if number == 0 && options[:no_for_zero]
          text = 'no'
        else
          text = number.to_s
        end
        text << (number == 1 ? " #{thing}" : " #{thing}s")
      end
    end
  end
end
