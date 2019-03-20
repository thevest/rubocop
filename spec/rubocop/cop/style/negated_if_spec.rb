# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::NegatedIf do
  subject(:cop) do
    config = RuboCop::Config.new(
      'Style/NegatedIf' => {
        'SupportedStyles' => %w[both prefix postfix],
        'EnforcedStyle' => 'both'
      }
    )
    described_class.new(config)
  end

  describe 'with “both” style' do
    it 'registers an offense for if with exclamation point condition' do
      expect_offense(<<-RUBY.strip_indent)
        if !a_condition
        ^^^^^^^^^^^^^^^ Favor `unless` over `if` for negative conditions.
          some_method
        end
        some_method if !a_condition
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Favor `unless` over `if` for negative conditions.
      RUBY
    end

    it 'registers an offense for unless with exclamation point condition' do
      expect_offense(<<-RUBY.strip_indent)
        unless !a_condition
        ^^^^^^^^^^^^^^^^^^^ Favor `if` over `unless` for negative conditions.
          some_method
        end
        some_method unless !a_condition
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Favor `if` over `unless` for negative conditions.
      RUBY
    end

    it 'registers an offense for if with "not" condition' do
      expect_offense(<<-RUBY.strip_indent)
        if not a_condition
        ^^^^^^^^^^^^^^^^^^ Favor `unless` over `if` for negative conditions.
          some_method
        end
        some_method if not a_condition
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Favor `unless` over `if` for negative conditions.
      RUBY
    end

    it 'accepts an if/else with negative condition' do
      expect_no_offenses(<<-RUBY.strip_indent)
        if !a_condition
          some_method
        else
          something_else
        end
        if not a_condition
          some_method
        elsif other_condition
          something_else
        end
      RUBY
    end

    it 'accepts an if where only part of the condition is negated' do
      expect_no_offenses(<<-RUBY.strip_indent)
        if !condition && another_condition
          some_method
        end
        if not condition or another_condition
          some_method
        end
        some_method if not condition or another_condition
      RUBY
    end

    it 'accepts an if where the condition is doubly negated' do
      expect_no_offenses(<<-RUBY.strip_indent)
        if !!condition
          some_method
        end
        some_method if !!condition
      RUBY
    end

    it 'is not confused by negated elsif' do
      expect_no_offenses(<<-RUBY.strip_indent)
        if test.is_a?(String)
          3
        elsif test.is_a?(Array)
          2
        elsif !test.nil?
          1
        end
      RUBY
    end

    it 'autocorrects for postfix' do
      corrected = autocorrect_source('bar if !foo')

      expect(corrected).to eq 'bar unless foo'
    end

    it 'autocorrects by replacing if not with unless' do
      corrected = autocorrect_source('something if !x.even?')
      expect(corrected).to eq 'something unless x.even?'
    end

    it 'autocorrects by replacing parenthesized if not with unless' do
      corrected = autocorrect_source('something if (!x.even?)')
      expect(corrected).to eq 'something unless (x.even?)'
    end

    it 'autocorrects by replacing unless not with if' do
      corrected = autocorrect_source('something unless !x.even?')
      expect(corrected).to eq 'something if x.even?'
    end

    it 'autocorrects for prefix' do
      corrected = autocorrect_source(<<-RUBY.strip_indent)
        if !foo
        end
      RUBY

      expect(corrected).to eq <<-RUBY.strip_indent
        unless foo
        end
      RUBY
    end
  end

  describe 'with “prefix” style' do
    subject(:cop) do
      config = RuboCop::Config.new(
        'Style/NegatedIf' => {
          'SupportedStyles' => %w[both prefix postfix],
          'EnforcedStyle' => 'prefix'
        }
      )

      described_class.new(config)
    end

    it 'registers an offense for prefix' do
      expect_offense(<<-RUBY.strip_indent)
        if !foo
        ^^^^^^^ Favor `unless` over `if` for negative conditions.
        end
      RUBY
    end

    it 'does not register an offense for postfix' do
      expect_no_offenses('foo if !bar')
    end

    it 'autocorrects for prefix' do
      corrected = autocorrect_source(<<-RUBY.strip_indent)
        if !foo
        end
      RUBY

      expect(corrected).to eq <<-RUBY.strip_indent
        unless foo
        end
      RUBY
    end
  end

  describe 'with “postfix” style' do
    subject(:cop) do
      config = RuboCop::Config.new(
        'Style/NegatedIf' => {
          'SupportedStyles' => %w[both prefix postfix],
          'EnforcedStyle' => 'postfix'
        }
      )

      described_class.new(config)
    end

    it 'registers an offense for postfix' do
      expect_offense(<<-RUBY.strip_indent)
        foo if !bar
        ^^^^^^^^^^^ Favor `unless` over `if` for negative conditions.
      RUBY
    end

    it 'does not register an offense for prefix' do
      expect_no_offenses(<<-RUBY.strip_indent)
        if !foo
        end
      RUBY
    end

    it 'autocorrects for postfix' do
      corrected = autocorrect_source('bar if !foo')

      expect(corrected).to eq 'bar unless foo'
    end
  end

  it 'does not blow up for ternary ops' do
    expect_no_offenses('a ? b : c')
  end

  it 'does not blow up on a negated ternary operator' do
    expect_no_offenses('!foo.empty? ? :bar : :baz')
  end

  it 'does not blow up for empty if condition' do
    expect_no_offenses(<<-RUBY.strip_indent)
      if ()
      end
    RUBY
  end

  it 'does not blow up for empty unless condition' do
    expect_no_offenses(<<-RUBY.strip_indent)
      unless ()
      end
    RUBY
  end
end
