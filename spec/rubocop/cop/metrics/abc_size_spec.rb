# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Metrics::AbcSize, :config do
  subject(:cop) { described_class.new(config) }

  context 'when Max is 0' do
    let(:cop_config) { { 'Max' => 0 } }

    it 'accepts an empty method' do
      expect_no_offenses(<<-RUBY.strip_indent)
        def method_name
        end
      RUBY
    end

    it 'accepts an empty `define_method`' do
      expect_no_offenses(<<-RUBY.strip_indent)
        define_method :method_name do
        end
      RUBY
    end

    it 'registers an offense for an if modifier' do
      expect_offense(<<-RUBY.strip_indent)
        def method_name
        ^^^^^^^^^^^^^^^ Assignment Branch Condition size for method_name is too high. [2.24/0]
          call_foo if some_condition # 0 + 2*2 + 1*1
        end
      RUBY
    end

    it 'registers an offense for an assignment of a local variable' do
      expect_offense(<<-RUBY.strip_indent)
        def method_name
        ^^^^^^^^^^^^^^^ Assignment Branch Condition size for method_name is too high. [1/0]
          x = 1
        end
      RUBY
    end

    it 'registers an offense for an assignment of an element' do
      expect_offense(<<-RUBY.strip_indent)
        def method_name
        ^^^^^^^^^^^^^^^ Assignment Branch Condition size for method_name is too high. [1.41/0]
          x[0] = 1
        end
      RUBY
    end

    it 'registers an offense for complex content including A, B, and C ' \
       'scores' do
      expect_offense(<<-RUBY.strip_indent)
        def method_name
        ^^^^^^^^^^^^^^^ Assignment Branch Condition size for method_name is too high. [5.74/0]
          my_options = Hash.new if 1 == 1 || 2 == 2 # 1, 1, 4
          my_options.each do |key, value|           # 0, 1, 0
            p key                                   # 0, 1, 0
            p value                                 # 0, 1, 0
          end
        end
      RUBY
    end

    it 'registers an offense for a `define_method`' do
      expect_offense(<<-RUBY.strip_indent)
        define_method :method_name do
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Assignment Branch Condition size for method_name is too high. [1/0]
          x = 1
        end
      RUBY
    end

    context 'target_ruby_version >= 2.3', :ruby23 do
      it 'treats safe navigation method calls like regular method calls' do
        expect_offense(<<-RUBY.strip_indent) # sqrt(0 + 2*2 + 0) => 2
          def method_name
          ^^^^^^^^^^^^^^^ Assignment Branch Condition size for method_name is too high. [2/0]
            object&.do_something
          end
        RUBY
      end
    end
  end

  context 'when Max is 2' do
    let(:cop_config) { { 'Max' => 2 } }

    it 'accepts two assignments' do
      expect_no_offenses(<<-RUBY.strip_indent)
        def method_name
          x = 1
          y = 2
        end
      RUBY
    end
  end

  context 'when Max is 2.3' do
    let(:cop_config) { { 'Max' => 2.3 } }

    it 'accepts a total score of 2.24' do
      expect_no_offenses(<<-RUBY.strip_indent)
        def method_name
          y = 1 if y == 1
        end
      RUBY
    end
  end

  {
    1.3 => '4.24/1.3', # no more than 2 decimals reported
    10.3 => '42.43/10.3',
    100.321 => '424.3/100.3', # 4 significant digits, so only 1 decimal here
    1000.3 => '4243/1000'
  }.each do |max, presentation|
    context "when Max is #{max}" do
      let(:cop_config) { { 'Max' => max } }

      it "reports size and max as #{presentation}" do
        # Build an amount of code large enough to register an offense.
        code = ['  x = Hash.new if 1 == 1 || 2 == 2'] * max

        inspect_source(['def method_name',
                        *code,
                        'end'].join("\n"))
        expect(cop.messages)
          .to eq(['Assignment Branch Condition size for method_name is too ' \
                  "high. [#{presentation}]"])
      end
    end
  end
end
