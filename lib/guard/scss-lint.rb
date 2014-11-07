# coding: utf-8

require 'guard'
require 'guard/plugin'

module Guard
  # This class gets API calls from `guard` and runs `scss-lint` command via
  # {Guard::ScssLint::Runner}. An instance of this class stays alive in a
  # `guard` command session.
  class ScssLint < Plugin
    autoload :Runner, 'guard/scss-lint/runner'

    attr_reader :options, :failed_paths

    def initialize(options = nil)
      super

      merge_with_default_opts(options)

      @failed_paths = []
    end

    def merge_with_default_opts(options = {})
      @options = {
        all_on_start: true,
        keep_failed:  true,
        notification: :failed,
        cli: nil,
        hide_stdout: false
      }.merge(options)
    end

    def start
      run_all if @options[:all_on_start]
    end

    def run_all
      UI.info 'Inspecting SCSS code style of all files'
      inspect_with_scsslint
    end

    def run_on_additions(paths)
      run_partially(paths)
    end

    def run_on_modifications(paths)
      run_partially(paths)
    end

    def reload
      @failed_paths = []
    end

    private

    def run_partially(paths)
      paths += @failed_paths if @options[:keep_failed]
      paths = clean_paths(paths)

      return if paths.empty?

      displayed_paths = paths.map { |path| smart_path(path) }
      UI.info "Inspecting SCSS code style: #{displayed_paths.join(' ')}"

      inspect_with_scsslint(paths)
    end

    def inspect_with_scsslint(paths = [])
      runner = Runner.new(@options)
      passed = runner.run(paths)
      @failed_paths = runner.failed_paths
      throw :task_has_failed unless passed
    rescue => error
      throw_inspect_error(error)
    end

    def throw_inspect_error(error)
      error_klazz = error.class.name
      UI.error 'The following exception occurred while running scss-lint: ' \
               "#{error.backtrace.first} #{error.message} (#{error_klazz})"
    end

    def clean_paths(paths)
      paths = paths.dup
      paths.map! { |path| File.expand_path(path) }.uniq!
      paths.reject! do |path|
        next true unless File.exist?(path)
        included_in_other_path?(path, paths)
      end
      paths
    end

    def included_in_other_path?(target_path, other_paths)
      dir_paths = other_paths.select { |path| File.directory?(path) }
      dir_paths.delete(target_path)
      dir_paths.any? do |dir_path|
        target_path.start_with?(dir_path)
      end
    end

    def smart_path(path)
      if path.start_with?(Dir.pwd)
        Pathname.new(path).relative_path_from(Pathname.getwd).to_s
      else
        path
      end
    end
  end
end
