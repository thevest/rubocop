# frozen_string_literal: true

require 'support/file_helper'
require 'rubocop/rake_task'

RSpec.describe RuboCop::RakeTask do
  include FileHelper

  before do
    Rake::Task.clear
  end

  after do
    Rake::Task.clear
  end

  describe 'defining tasks' do
    it 'creates a rubocop task and a rubocop auto_correct task' do
      described_class.new

      expect(Rake::Task.task_defined?(:rubocop)).to be true
      expect(Rake::Task.task_defined?('rubocop:auto_correct')).to be true
    end

    it 'creates a named task and a named auto_correct task' do
      described_class.new(:lint_lib)

      expect(Rake::Task.task_defined?(:lint_lib)).to be true
      expect(Rake::Task.task_defined?('lint_lib:auto_correct')).to be true
    end
  end

  describe 'running tasks' do
    before do
      $stdout = StringIO.new
      $stderr = StringIO.new
    end

    after do
      $stdout = STDOUT
      $stderr = STDERR
    end

    it 'runs with default options' do
      described_class.new

      cli = instance_spy(RuboCop::CLI, run: 0)
      allow(RuboCop::CLI).to receive(:new) { cli }

      Rake::Task['rubocop'].execute

      expect(cli).to have_received(:run).with([])
    end

    it 'runs with specified options if a block is given' do
      described_class.new do |task|
        task.patterns = ['lib/**/*.rb']
        task.formatters = ['files']
        task.fail_on_error = false
        task.options = ['--display-cop-names']
        task.verbose = false
      end

      cli = instance_spy(RuboCop::CLI, run: 0)
      allow(RuboCop::CLI).to receive(:new) { cli }
      options = ['--format', 'files', '--display-cop-names', 'lib/**/*.rb']

      Rake::Task['rubocop'].execute

      expect(cli).to have_received(:run).with(options)
    end

    it 'allows nested arrays inside formatters, options, and requires' do
      described_class.new do |task|
        task.formatters = [['files']]
        task.requires = [['library']]
        task.options = [['--display-cop-names']]
      end

      cli = instance_spy(RuboCop::CLI, run: 0)
      allow(RuboCop::CLI).to receive(:new) { cli }
      options = ['--format', 'files', '--require', 'library',
                 '--display-cop-names']

      Rake::Task['rubocop'].execute

      expect(cli).to have_received(:run).with(options)
    end

    it 'will not error when result is not 0 and fail_on_error is false' do
      described_class.new do |task|
        task.fail_on_error = false
      end

      cli = instance_double(RuboCop::CLI, run: 1)
      allow(RuboCop::CLI).to receive(:new) { cli }

      expect { Rake::Task['rubocop'].execute }.not_to raise_error
    end

    it 'exits when result is not 0 and fail_on_error is true' do
      described_class.new

      cli = instance_double(RuboCop::CLI, run: 1)
      allow(RuboCop::CLI).to receive(:new) { cli }

      expect { Rake::Task['rubocop'].execute }.to raise_error(SystemExit)
    end

    it 'uses the default formatter from .rubocop.yml if no formatter ' \
       'option is given', :isolated_environment do
      create_file('.rubocop.yml', <<-YAML.strip_indent)
        AllCops:
          DefaultFormatter: offenses
      YAML
      create_file('test.rb', '$:')

      described_class.new do |task|
        task.options = ['test.rb']
      end

      expect { Rake::Task['rubocop'].execute }.to raise_error(SystemExit)

      expect($stdout.string).to eq(<<-RESULT.strip_indent)
        Running RuboCop...

        1  Style/SpecialGlobalVars
        --
        1  Total

      RESULT
      expect($stderr.string.strip).to eq 'RuboCop failed!'
    end

    context 'auto_correct' do
      it 'runs with --auto-correct' do
        described_class.new

        cli = instance_spy(RuboCop::CLI, run: 0)
        allow(RuboCop::CLI).to receive(:new) { cli }
        options = ['--auto-correct']

        Rake::Task['rubocop:auto_correct'].execute

        expect(cli).to have_received(:run).with(options)
      end

      it 'runs with with the options that were passed to its parent task' do
        described_class.new do |task|
          task.patterns = ['lib/**/*.rb']
          task.formatters = ['files']
          task.fail_on_error = false
          task.options = ['-D']
          task.verbose = false
        end

        cli = instance_double(RuboCop::CLI, run: 0)
        allow(RuboCop::CLI).to receive(:new) { cli }
        options = ['--auto-correct', '--format', 'files', '-D', 'lib/**/*.rb']

        Rake::Task['rubocop:auto_correct'].execute

        expect(cli).to have_received(:run).with(options)
      end
    end
  end
end
