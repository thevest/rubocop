# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Layout::EmptyLinesAroundMethodBody do
  subject(:cop) { described_class.new }

  it 'registers an offense for method body starting with a blank' do
    inspect_source(<<-RUBY.strip_indent)
      def some_method

        do_something
      end
    RUBY
    expect(cop.messages)
      .to eq(['Extra empty line detected at method body beginning.'])
  end

  # The cop only registers an offense if the extra line is completely empty. If
  # there is trailing whitespace, then that must be dealt with first. Having
  # two cops registering offense for the line with only spaces would cause
  # havoc in auto-correction.
  it 'accepts method body starting with a line with spaces' do
    expect_no_offenses(['def some_method',
                        '  ',
                        '  do_something',
                        'end'].join("\n"))
  end

  it 'autocorrects method body starting with a blank' do
    corrected = autocorrect_source(<<-RUBY.strip_indent)
      def some_method

        do_something
      end
    RUBY
    expect(corrected).to eq <<-RUBY.strip_indent
      def some_method
        do_something
      end
    RUBY
  end

  it 'registers an offense for class method body starting with a blank' do
    inspect_source(<<-RUBY.strip_indent)
      def Test.some_method

        do_something
      end
    RUBY
    expect(cop.messages)
      .to eq(['Extra empty line detected at method body beginning.'])
  end

  it 'autocorrects class method body starting with a blank' do
    corrected = autocorrect_source(<<-RUBY.strip_indent)
      def Test.some_method

        do_something
      end
    RUBY
    expect(corrected).to eq <<-RUBY.strip_indent
      def Test.some_method
        do_something
      end
    RUBY
  end

  it 'registers an offense for method body ending with a blank' do
    inspect_source(<<-RUBY.strip_indent)
      def some_method
        do_something

      end
    RUBY
    expect(cop.messages)
      .to eq(['Extra empty line detected at method body end.'])
  end

  it 'registers an offense for class method body ending with a blank' do
    inspect_source(<<-RUBY.strip_indent)
      def Test.some_method
        do_something

      end
    RUBY
    expect(cop.messages)
      .to eq(['Extra empty line detected at method body end.'])
  end

  it 'is not fooled by single line methods' do
    expect_no_offenses(<<-RUBY.strip_indent)
      def some_method; do_something; end

      something_else
    RUBY
  end
end
