# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Lint::RequireParentheses do
  subject(:cop) { described_class.new }

  it 'registers an offense for missing parentheses around expression with ' \
     '&& operator' do
    expect_offense(<<-RUBY.strip_indent)
      if day.is? 'monday' && month == :jan
         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use parentheses in the method call to avoid confusion about precedence.
        foo
      end
    RUBY
  end

  it 'registers an offense for missing parentheses around expression with ' \
     '|| operator' do
    expect_offense(<<-RUBY.strip_indent)
      day_is? 'tuesday' || true
      ^^^^^^^^^^^^^^^^^^^^^^^^^ Use parentheses in the method call to avoid confusion about precedence.
    RUBY
  end

  it 'registers an offense for missing parentheses around expression in ' \
     'ternary' do
    expect_offense(<<-RUBY.strip_indent)
      wd.include? 'tuesday' && true == true ? a : b
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use parentheses in the method call to avoid confusion about precedence.
    RUBY
  end

  context 'when using safe navigation operator', :ruby23 do
    it 'registers an offense for missing parentheses around expression with ' \
       '&& operator' do
      expect_offense(<<-RUBY.strip_indent)
        if day&.is? 'monday' && month == :jan
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use parentheses in the method call to avoid confusion about precedence.
          foo
        end
      RUBY
    end
  end

  it 'accepts missing parentheses around expression with + operator' do
    expect_no_offenses(<<-RUBY.strip_indent)
      if day_is? 'tuesday' + rest
      end
    RUBY
  end

  it 'accepts method calls without parentheses followed by keyword and/or' do
    expect_no_offenses(<<-RUBY.strip_indent)
      if day.is? 'tuesday' and month == :jan
      end
      if day.is? 'tuesday' or month == :jan
      end
    RUBY
  end

  it 'accepts method calls that are all operations' do
    expect_no_offenses(<<-RUBY.strip_indent)
      if current_level == max + 1
      end
    RUBY
  end

  it 'accepts condition that is not a call' do
    expect_no_offenses(<<-RUBY.strip_indent)
      if @debug
      end
    RUBY
  end

  it 'accepts parentheses around expression with boolean operator' do
    expect_no_offenses(<<-RUBY.strip_indent)
      if day.is?('tuesday' && true == true)
      end
    RUBY
  end

  it 'accepts method call with parentheses in ternary' do
    expect_no_offenses("wd.include?('tuesday' && true == true) ? a : b")
  end

  it 'accepts missing parentheses when method is not a predicate' do
    expect_no_offenses("weekdays.foo 'tuesday' && true == true")
  end

  it 'accepts calls to methods that are setters' do
    expect_no_offenses('s.version = @version || ">= 1.8.5"')
  end

  it 'accepts calls to methods that are operators' do
    expect_no_offenses('a[b || c]')
  end
end
