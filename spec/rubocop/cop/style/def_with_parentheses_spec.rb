# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::DefWithParentheses do
  subject(:cop) { described_class.new }

  it 'reports an offense for def with empty parens' do
    expect_offense(<<-RUBY.strip_indent)
      def func()
              ^ Omit the parentheses in defs when the method doesn't accept any arguments.
      end
    RUBY
  end

  it 'reports an offense for class def with empty parens' do
    expect_offense(<<-RUBY.strip_indent)
      def Test.func()
                   ^ Omit the parentheses in defs when the method doesn't accept any arguments.
      end
    RUBY
  end

  it 'accepts def with arg and parens' do
    expect_no_offenses(<<-RUBY.strip_indent)
      def func(a)
      end
    RUBY
  end

  it 'accepts empty parentheses in one liners' do
    expect_no_offenses("def to_s() join '/' end")
  end

  it 'auto-removes unneeded parens' do
    new_source = autocorrect_source(<<-RUBY.strip_indent)
      def test();
      something
      end
    RUBY
    expect(new_source).to eq(<<-RUBY.strip_indent)
      def test;
      something
      end
    RUBY
  end
end
