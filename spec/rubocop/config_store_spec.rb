# frozen_string_literal: true

RSpec.describe RuboCop::ConfigStore do
  subject(:config_store) { described_class.new }

  before do
    allow(RuboCop::ConfigLoader).to receive(:configuration_file_for) do |arg|
      # File tree:
      # file1
      # dir/.rubocop.yml
      # dir/file2
      # dir/subdir/file3
      (arg =~ /dir/ ? 'dir' : '.') + '/.rubocop.yml'
    end
    allow(RuboCop::ConfigLoader)
      .to receive(:configuration_from_file) { |arg| arg }
    allow(RuboCop::ConfigLoader)
      .to receive(:load_file) { |arg| RuboCop::Config.new(arg) }
    allow(RuboCop::ConfigLoader)
      .to receive(:merge_with_default) { |config| "merged #{config.to_h}" }
    allow(RuboCop::ConfigLoader)
      .to receive(:default_configuration).and_return('default config')
  end

  describe '.for' do
    it 'always uses config specified in command line' do
      config_store.options_config = { options_config: true }
      expect(config_store.for('file1')).to eq('merged {:options_config=>true}')
    end

    context 'when no config specified in command line' do
      it 'gets config path and config from cache if available' do
        config_store.for('dir/file2')
        config_store.for('dir/file2')
        config_store.for('dir/subdir/file3')

        expect(RuboCop::ConfigLoader)
          .to have_received(:configuration_file_for).with('dir').once
        expect(RuboCop::ConfigLoader)
          .to have_received(:configuration_file_for).with('dir/subdir').once
        # The stub returns the same config path for dir and dir/subdir.
        expect(RuboCop::ConfigLoader)
          .to have_received(:configuration_from_file)
          .with('dir/.rubocop.yml').once
      end

      it 'searches for config path if not available in cache' do
        allow(RuboCop::ConfigLoader).to receive(:configuration_file_for)
        allow(RuboCop::ConfigLoader).to receive(:configuration_from_file)

        config_store.for('file1')

        expect(RuboCop::ConfigLoader)
          .to have_received(:configuration_file_for).once
        expect(RuboCop::ConfigLoader)
          .to have_received(:configuration_from_file).once
      end

      context 'when --force-default-config option is specified' do
        it 'uses default config without searching for config path' do
          allow(RuboCop::ConfigLoader).to receive(:configuration_file_for)
          allow(RuboCop::ConfigLoader).to receive(:configuration_from_file)

          config_store.force_default_config!

          expect(RuboCop::ConfigLoader)
            .not_to have_received(:configuration_file_for)
          expect(RuboCop::ConfigLoader)
            .not_to have_received(:configuration_from_file)

          expect(config_store.for('file1')).to eq('default config')
        end
      end
    end
  end
end
