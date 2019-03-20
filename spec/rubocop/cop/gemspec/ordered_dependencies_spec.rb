# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Gemspec::OrderedDependencies, :config do
  subject(:cop) { described_class.new(config) }

  let(:cop_config) do
    {
      'TreatCommentsAsGroupSeparators' => treat_comments_as_group_separators,
      'Include' => nil
    }
  end
  let(:treat_comments_as_group_separators) { false }
  let(:message) do
    'Dependencies should be sorted in an alphabetical order within their ' \
      'section of the gemspec. Dependency `%s` should appear before `%s`.'
  end

  shared_examples 'ordered dependency' do |add_dependency|
    context "when #{add_dependency}" do
      context 'When gems are alphabetically sorted' do
        it 'does not register any offenses' do
          expect_no_offenses(<<-RUBY.strip_indent)
            Gem::Specification.new do |spec|
              spec.#{add_dependency} 'rspec'
              spec.#{add_dependency} 'rubocop'
            end
          RUBY
        end
      end

      context 'when gems are not alphabetically sorted' do
        let(:source) { <<-RUBY.strip_indent }
          Gem::Specification.new do |spec|
            spec.#{add_dependency} 'rubocop'
            spec.#{add_dependency} 'rspec'
          end
        RUBY

        it 'registers an offense' do
          expect_offense(offense_message)
        end

        it 'autocorrects' do
          new_source = autocorrect_source_with_loop(source)
          expect(new_source).to eq(<<-RUBY.strip_indent)
            Gem::Specification.new do |spec|
              spec.#{add_dependency} 'rspec'
              spec.#{add_dependency} 'rubocop'
            end
          RUBY
        end
      end

      context 'when each individual group of line is sorted' do
        it 'does not register any offenses' do
          expect_no_offenses(<<-RUBY.strip_indent)
            Gem::Specification.new do |spec|
              spec.#{add_dependency} 'rspec'
              spec.#{add_dependency} 'rubocop'

              spec.#{add_dependency} 'hello'
              spec.#{add_dependency} 'world'
            end
          RUBY
        end
      end

      context 'when dependency is separated by multiline comment' do
        let(:source) { <<-RUBY.strip_indent }
          Gem::Specification.new do |spec|
            # For code quality
            spec.#{add_dependency} 'rubocop'
            # For
            # test
            spec.#{add_dependency} 'rspec'
          end
        RUBY

        context 'with TreatCommentsAsGroupSeparators: true' do
          let(:treat_comments_as_group_separators) { true }

          it 'accepts' do
            expect_no_offenses(<<-RUBY.strip_indent)
              Gem::Specification.new do |spec|
                # For code quality
                spec.#{add_dependency} 'rubocop'
                # For
                # test
                spec.#{add_dependency} 'rspec'
              end
            RUBY
          end
        end

        context 'with TreatCommentsAsGroupSeparators: false' do
          it 'registers an offense' do
            expect_offense(offense_message_with_multiline_comment)
          end

          it 'autocorrects' do
            new_source = autocorrect_source_with_loop(source)
            expect(new_source).to eq(<<-RUBY.strip_indent)
              Gem::Specification.new do |spec|
                # For
                # test
                spec.#{add_dependency} 'rspec'
                # For code quality
                spec.#{add_dependency} 'rubocop'
              end
            RUBY
          end
        end
      end
    end
  end

  it_behaves_like 'ordered dependency', 'add_dependency' do
    let(:offense_message) { <<-RUBY.strip_indent }
      Gem::Specification.new do |spec|
        spec.add_dependency 'rubocop'
        spec.add_dependency 'rspec'
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(message, 'rspec', 'rubocop')}
      end
    RUBY

    let(:offense_message_with_multiline_comment) { <<-RUBY.strip_indent }
      Gem::Specification.new do |spec|
        # For code quality
        spec.add_dependency 'rubocop'
        # For
        # test
        spec.add_dependency 'rspec'
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(message, 'rspec', 'rubocop')}
      end
    RUBY
  end

  it_behaves_like 'ordered dependency', 'add_runtime_dependency' do
    let(:offense_message) { <<-RUBY.strip_indent }
      Gem::Specification.new do |spec|
        spec.add_runtime_dependency 'rubocop'
        spec.add_runtime_dependency 'rspec'
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(message, 'rspec', 'rubocop')}
      end
    RUBY

    let(:offense_message_with_multiline_comment) { <<-RUBY.strip_indent }
      Gem::Specification.new do |spec|
        # For code quality
        spec.add_runtime_dependency 'rubocop'
        # For
        # test
        spec.add_runtime_dependency 'rspec'
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(message, 'rspec', 'rubocop')}
      end
    RUBY
  end

  it_behaves_like 'ordered dependency', 'add_development_dependency' do
    let(:offense_message) { <<-RUBY.strip_indent }
      Gem::Specification.new do |spec|
        spec.add_development_dependency 'rubocop'
        spec.add_development_dependency 'rspec'
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(message, 'rspec', 'rubocop')}
      end
    RUBY

    let(:offense_message_with_multiline_comment) { <<-RUBY.strip_indent }
      Gem::Specification.new do |spec|
        # For code quality
        spec.add_development_dependency 'rubocop'
        # For
        # test
        spec.add_development_dependency 'rspec'
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(message, 'rspec', 'rubocop')}
      end
    RUBY
  end

  context 'when different dependencies are consecutive' do
    it 'does not register any offenses' do
      expect_no_offenses(<<-RUBY.strip_indent)
        Gem::Specification.new do |spec|
          spec.add_dependency         'rubocop'
          spec.add_runtime_dependency 'rspec'
        end
      RUBY
    end
  end

  context 'When using method call to gem names' do
    it 'does not register any offenses' do
      expect_no_offenses(<<-RUBY.strip_indent)
        Gem::Specification.new do |spec|
          spec.add_dependency         'rubocop'.freeze
          spec.add_runtime_dependency 'rspec'.freeze
        end
      RUBY
    end
  end
end
