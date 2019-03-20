# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Naming::UncommunicativeBlockParamName, :config do
  subject(:cop) { described_class.new(config) }

  let(:cop_config) do
    {
      'MinNameLength' => 2,
      'AllowNamesEndingInNumbers' => false
    }
  end

  it 'does not register for block without parameters' do
    expect_no_offenses(<<-RUBY.strip_indent)
      something do
        do_stuff
      end
    RUBY
  end

  it 'does not register for brace block without parameters' do
    expect_no_offenses(<<-RUBY.strip_indent)
      something { do_stuff }
    RUBY
  end

  it 'does not register offense for valid parameter names' do
    expect_no_offenses(<<-RUBY.strip_indent)
      something { |foo, bar| do_stuff }
    RUBY
  end

  it 'registers offense when param ends in number' do
    expect_offense(<<-RUBY.strip_indent)
      something { |foo1, bar| do_stuff }
                   ^^^^ Do not end block parameter with a number.
    RUBY
  end

  it 'registers offense when param is less than minimum length' do
    expect_offense(<<-RUBY.strip_indent)
      something do |x|
                    ^ Block parameter must be at least 2 characters long.
        do_stuff
      end
    RUBY
  end

  it 'registers offense when param contains uppercase characters' do
    expect_offense(<<-RUBY.strip_indent)
      something { |number_One| do_stuff }
                   ^^^^^^^^^^ Only use lowercase characters for block parameter.
    RUBY
  end

  it 'can register multiple offenses in one block' do
    expect_offense(<<-RUBY.strip_indent)
      something do |y, num1, oFo|
                    ^ Block parameter must be at least 2 characters long.
                       ^^^^ Do not end block parameter with a number.
                             ^^^ Only use lowercase characters for block parameter.
        do_stuff
      end
    RUBY
  end

  context 'with AllowedNames' do
    let(:cop_config) do
      {
        'AllowedNames' => %w[foo1 foo2],
        'AllowNamesEndingInNumbers' => false
      }
    end

    it 'accepts specified block param names' do
      expect_no_offenses(<<-RUBY.strip_indent)
        something { |foo1, foo2| do_things }
      RUBY
    end

    it 'registers unlisted offensive names' do
      expect_offense(<<-RUBY.strip_indent)
        something { |bar, bar1| do_things }
                          ^^^^ Do not end block parameter with a number.
      RUBY
    end
  end

  context 'with ForbiddenNames' do
    let(:cop_config) do
      {
        'ForbiddenNames' => %w[arg]
      }
    end

    it 'registers offense for param listed as forbidden' do
      expect_offense(<<-RUBY.strip_indent)
        something { |arg| do_stuff }
                     ^^^ Do not use arg as a name for a block parameter.
      RUBY
    end

    it "accepts param that uses a forbidden name's letters" do
      expect_no_offenses(<<-RUBY.strip_indent)
        something { |foo_arg| do_stuff }
      RUBY
    end
  end

  context 'with AllowNamesEndingInNumbers' do
    let(:cop_config) do
      {
        'AllowNamesEndingInNumbers' => true
      }
    end

    it 'accept params that end in numbers' do
      expect_no_offenses(<<-RUBY.strip_indent)
        something { |foo1, bar2, qux3| do_that_stuff }
      RUBY
    end
  end
end
