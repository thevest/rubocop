# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::WhileUntilDo do
  subject(:cop) { described_class.new }

  it 'registers an offense for do in multiline while' do
    expect_offense(<<-RUBY.strip_indent)
      while cond do
                 ^^ Do not use `do` with multi-line `while`.
      end
    RUBY

    expect_correction(<<-RUBY.strip_indent)
      while cond
      end
    RUBY
  end

  it 'registers an offense for do in multiline until' do
    expect_offense(<<-RUBY.strip_indent)
      until cond do
                 ^^ Do not use `do` with multi-line `until`.
      end
    RUBY

    expect_correction(<<-RUBY.strip_indent)
      until cond
      end
    RUBY
  end

  it 'accepts do in single-line while' do
    expect_no_offenses('while cond do something end')
  end

  it 'accepts do in single-line until' do
    expect_no_offenses('until cond do something end')
  end

  it 'accepts multi-line while without do' do
    expect_no_offenses(<<-RUBY.strip_indent)
      while cond
      end
    RUBY
  end

  it 'accepts multi-line until without do' do
    expect_no_offenses(<<-RUBY.strip_indent)
      until cond
      end
    RUBY
  end
end
