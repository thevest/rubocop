# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::AsciiComments do
  subject(:cop) { described_class.new }

  it 'registers an offense for a comment with non-ascii chars' do
    expect_offense(<<-RUBY.strip_indent)
      # 这是什么？
        ^^^^^ Use only ascii symbols in comments.
    RUBY
  end

  it 'registers an offense for comments with mixed chars' do
    expect_offense(<<-RUBY.strip_indent)
      # foo ∂ bar
            ^ Use only ascii symbols in comments.
    RUBY
  end

  it 'accepts comments with only ascii chars' do
    expect_no_offenses('# AZaz1@$%~,;*_`|')
  end

  context 'when certain non-ascii chars are allowed', :config do
    subject(:cop) { described_class.new(config) }

    let(:cop_config) { { 'AllowedChars' => ['∂'] } }

    it 'accepts comment with allowed non-ascii chars' do
      expect_no_offenses('# foo ∂ bar')
    end

    it 'registers an offense for comments with non-allowed non-ascii chars' do
      expect_offense(<<-RUBY.strip_indent)
        # 这是什么？
          ^^^^^ Use only ascii symbols in comments.
      RUBY
    end
  end
end
