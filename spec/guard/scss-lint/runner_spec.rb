# coding: utf-8

require 'spec_helper.rb'

describe Guard::ScssLint::Runner do
  subject(:runner) { Guard::ScssLint::Runner.new(options) }
  let(:options) { {} }

  describe '#run' do
    subject { super().run(paths) }
    let(:paths) { ['spec/spec_helper.rb'] }

    before do
      allow(runner).to receive(:system)
    end

    it 'executes scss-lint' do
      expect(runner).to receive(:system) do |*args|
        expect(args.first).to eq('scss-lint')
      end
      runner.run
    end

    context 'when scss-lint exited with 0 status' do
      before do
        allow(runner).to receive(:system).and_return(true)
      end
      it { should be_truthy }
    end

    context 'when scss-lint exited with non 0 status' do
      before do
        allow(runner).to receive(:system).and_return(false)
      end
      it { should be_falsey }
    end

    shared_examples 'notifies', :notifies do
      it 'notifies' do
        expect(runner).to receive(:notify)
        runner.run
      end
    end

    shared_examples 'does not notify', :does_not_notify do
      it 'does not notify' do
        expect(runner).not_to receive(:notify)
        runner.run
      end
    end

    shared_examples 'notification' do |expectations|
      context 'when passed' do
        before do
          allow(runner).to receive(:system).and_return(true)
        end

        if expectations[:passed]
          include_examples 'notifies'
        else
          include_examples 'does not notify'
        end
      end

      context 'when failed' do
        before do
          allow(runner).to receive(:system).and_return(false)
        end

        if expectations[:failed]
          include_examples 'notifies'
        else
          include_examples 'does not notify'
        end
      end
    end

    context 'when :notification option is true' do
      let(:options) { { notification: true } }
      include_examples 'notification', { passed: true, failed: true }
    end

    context 'when :notification option is :failed' do
      let(:options) { { notification: :failed } }
      include_examples 'notification', { passed: false, failed: true }
    end

    context 'when :notification option is false' do
      let(:options) { { notification: false } }
      include_examples 'notification', { passed: false, failed: false }
    end
  end

  describe '#build_command' do
    subject(:build_command) { runner.build_command(paths) }
    let(:options) { { cli: %w(--exclude test/foobar.scss --config test/test_config.yml) } }
    let(:paths) { %w(test/foo.scss test/bar.scss test/foobar.scss) }

    # FIXME: STUB
    # context 'when :cli option includes formatter for console' do
    #   let(:options) { { cli: %w(--format simple) } }
    #
    #   it 'does not add args for the default formatter for console' do
    #     pending
    #     expect(build_command[0..2]).not_to eq(%w(scss-lint --format Default))
    #   end
    # end

    # FIXME: STUB
    # context 'when :cli option does not include formatter for console' do
    #   let(:options) { { cli: %w(--format simple --out simple.txt) } }
    #
    #   it 'adds args for the default formatter for console' do
    #     pending
    #     expect(build_command[0..2]).to eq(%w(scss-lint --format Default))
    #   end
    # end

    it 'adds args for JSON formatter' do
      expect(build_command[1..2]).to eq(%w(--format JSON))
    end

    it 'adds args for output file path of JSON formatter' do
      expect(build_command[3]).to eq('--out')
      expect(build_command[4]).not_to be_empty
    end

    # FIXME: STUB
    # it 'adds --force-exclusion option' do
    #   pending
    #   expect(build_command[7]).to eq('--force-exclusion')
    # end

    it 'adds args specified by user' do
      options[:cli].each do |opt|
        expect(build_command).to include(opt)
      end
    end

    it 'adds the passed paths' do
      paths.each { |path| expect(build_command).to include(path) }
    end
  end

  describe '#args_specified_by_user' do
    context 'when :cli option is nil' do
      let(:options) { { cli: nil } }

      it 'returns empty array' do
        expect(runner.args_specified_by_user).to eq([])
      end
    end

    context 'when :cli option is an array' do
      let(:options) { { cli: ['--out', 'output file.txt'] } }

      it 'just returns the array' do
        expect(runner.args_specified_by_user).to eq(['--out', 'output file.txt'])
      end
    end

    context 'when :cli option is a string' do
      let(:options) { { cli: '--out "output file.txt"' } }

      it 'returns an array from String#shellsplit' do
        expect(runner.args_specified_by_user).to eq(['--out', 'output file.txt'])
      end
    end

    context 'when :cli option is not array or string' do
      let(:options) { { cli: { key: 'value' } } }

      it 'raises error' do
        expect { runner.args_specified_by_user }.to raise_error
      end
    end
  end

  describe '#include_formatter_for_console?' do
    subject(:include_formatter_for_console?) { runner.include_formatter_for_console?(args) }

    context 'when the passed args include a -f/--format' do
      context 'but does not include an -o/--output' do
        let(:args) { %w(--format simple --debug) }

        it 'returns true' do
          expect(include_formatter_for_console?).to be_truthy
        end
      end

      context 'and include an -o/--output just after the -f/--format' do
        let(:args) { %w(--format simple --out simple.txt) }

        it 'returns false' do
          expect(include_formatter_for_console?).to be_falsey
        end
      end

      context 'and include an -o/--output after the -f/--format across another arg' do
        let(:args) { %w(--format simple --debug --out simple.txt) }

        it 'returns false' do
          expect(include_formatter_for_console?).to be_falsey
        end
      end
    end

    context 'when the passed args include a -f with its arg without separator' do
      context 'but does not include an -o/--output' do
        let(:args) { %w(-fs --debug) }

        it 'returns true' do
          expect(include_formatter_for_console?).to be_truthy
        end
      end

      context 'and include an -o with its arg without separator just after the -f/--format' do
        let(:args) { %w(-fs -osimple.txt) }

        it 'returns false' do
          expect(include_formatter_for_console?).to be_falsey
        end
      end
    end

    context 'when the passed args include multiple -f/--format' do
      context 'and all -f/--format have associated -o/--out' do
        let(:args) { %w(--format simple --out simple.txt --format emacs --out emacs.txt) }

        it 'returns false' do
          expect(include_formatter_for_console?).to be_falsey
        end
      end

      context 'and any -f/--format has associated -o/--out' do
        let(:args) { %w(--format simple --format emacs --out emacs.txt) }

        it 'returns true' do
          expect(include_formatter_for_console?).to be_truthy
        end
      end

      context 'and no -f/--format has associated -o/--out' do
        let(:args) { %w(--format simple --format emacs) }

        it 'returns true' do
          expect(include_formatter_for_console?).to be_truthy
        end
      end
    end

    context 'when the passed args do not include -f/--format' do
      let(:args) { %w(--debug) }

      it 'returns false' do
        expect(include_formatter_for_console?).to be_falsey
      end
    end
  end

  describe '#json_file_path' do
    it 'is not world readable' do
      expect(File.world_readable?(runner.json_file_path)).to be_falsey
    end
  end

  shared_context 'JSON file', :json_file do
    before do
      # NOTE: Cannot use `let` in shared_context currently, throws seg fault.
      opts = { cli: ['--format', 'JSON', '--out', runner.json_file_path] } 
      ::Guard::ScssLint::Runner.new(opts).run(%w{test/foo.scss test/bar.scss test/foobar.scss})
    end
  end

  describe '#result', :json_file do
    it 'parses JSON file' do
      expect(runner.result.size).to eq(3)
    end
  end

  describe '#notify' do
    let(:options) { { } }
    let(:paths) { [] }
    subject { super().run(paths) }
    before do
      allow(runner).to receive(:result).and_return(
        {
          summary: {
            offense_count: 4,
            target_file_count: 3,
            inspected_file_count: 2
          }
        }
      )
    end

    it 'notifies summary' do
      expect(Guard::Notifier).to receive(:notify) do |message, _options|
        expect(message).to eq('2 files inspected, 4 offenses detected')
        # expect(message).to eq(runner.result.inspect)
      end
      runner.notify(true)
    end

    it 'notifies with title "scss-lint results"' do
      expect(Guard::Notifier).to receive(:notify) do |_message, options|
        expect(options[:title]).to eq('scss-lint results')
      end
      runner.notify(true)
    end

    context 'when passed' do
      it 'shows success image' do
        expect(Guard::Notifier).to receive(:notify) do |_message, options|
          expect(options[:image]).to eq(:success)
        end
        runner.notify(true)
      end
    end

    context 'when failed' do
      it 'shows failed image' do
        expect(Guard::Notifier).to receive(:notify) do |_message, options|
          expect(options[:image]).to eq(:failed)
        end
        runner.notify(false)
      end
    end
  end

  describe '#summary_text' do
    before do
      allow(runner).to receive(:result).and_return(
        {
          summary: {
            offense_count: offense_count,
            target_file_count: target_file_count,
            inspected_file_count: inspected_file_count
          }
        }
      )
    end

    subject(:summary_text) { runner.summary_text }

    let(:offense_count)        { 0 }
    let(:target_file_count)    { 0 }
    let(:inspected_file_count) { 0 }

    context 'when no files are inspected' do
      let(:inspected_file_count) { 0 }
      it 'includes "0 files"' do
        expect(summary_text).to include '0 files'
      end
    end

    context 'when a file is inspected' do
      let(:inspected_file_count) { 1 }
      it 'includes "1 file"' do
        expect(summary_text).to include '1 file'
      end
    end

    context 'when 2 files are inspected' do
      let(:inspected_file_count) { 2 }
      it 'includes "2 files"' do
        expect(summary_text).to include '2 files'
      end
    end

    context 'when no offenses are detected' do
      let(:offense_count) { 0 }
      it 'includes "no offenses"' do
        expect(summary_text).to include 'no offenses'
      end
    end

    context 'when an offense is detected' do
      let(:offense_count) { 1 }
      it 'includes "1 offense"' do
        expect(summary_text).to include '1 offense'
      end
    end

    context 'when 2 offenses are detected' do
      let(:offense_count) { 2 }
      it 'includes "2 offenses"' do
        expect(summary_text).to include '2 offenses'
      end
    end

    context 'with spelling "offence" in old scss-lint' do
      before do
        allow(runner).to receive(:result).and_return(
          {
            summary: {
              offence_count: 2,
              target_file_count: 1,
              inspected_file_count: 1
            }
          }
        )
      end

      it 'handles the spelling' do
        expect(summary_text).to include '2 offenses'
      end
    end
  end

  describe '#failed_paths', :json_file do
    it 'returns file paths which have offenses' do
      expect(runner.failed_paths).to eq(['lib/bar.rb'])
    end

    context 'with spelling "offence" in old scss-lint' do
      before do
        json = <<-END
          {
            "files": [
              {
                "path": "lib/foo.rb",
                "offences": []
              }, {
                "path": "lib/bar.rb",
                "offences": [
                  {
                    "severity": "convention",
                    "message": "Line is too long. [81/79]",
                    "cop_name": "LineLength",
                    "location": {
                      "line": 546,
                      "column": 80
                    }
                  }, {
                    "severity": "warning",
                    "message": "Unreachable code detected.",
                    "cop_name": "UnreachableCode",
                    "location": {
                      "line": 15,
                      "column": 9
                    }
                  }
                ]
              }
            ]
          }
        END
        File.write(runner.json_file_path, json)
      end

      it 'handles the spelling' do
        expect(runner.failed_paths).to eq(['lib/bar.rb'])
      end
    end
  end
end
