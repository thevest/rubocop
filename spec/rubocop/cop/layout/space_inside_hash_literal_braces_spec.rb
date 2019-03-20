# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Layout::SpaceInsideHashLiteralBraces, :config do
  subject(:cop) { described_class.new(config) }

  let(:cop_config) { { 'EnforcedStyle' => 'space' } }

  context 'with space inside empty braces not allowed' do
    let(:cop_config) { { 'EnforcedStyleForEmptyBraces' => 'no_space' } }

    it 'accepts empty braces with no space inside' do
      expect_no_offenses('h = {}')
    end

    it 'registers an offense for empty braces with space inside' do
      expect_offense(<<-RUBY.strip_indent)
        h = { }
             ^ Space inside empty hash literal braces detected.
      RUBY
    end

    it 'auto-corrects unwanted space' do
      new_source = autocorrect_source('h = { }')
      expect(new_source).to eq('h = {}')
    end
  end

  context 'with space inside empty braces allowed' do
    let(:cop_config) { { 'EnforcedStyleForEmptyBraces' => 'space' } }

    it 'accepts empty braces with space inside' do
      expect_no_offenses('h = { }')
    end

    it 'registers an offense for empty braces with no space inside' do
      expect_offense(<<-RUBY.strip_indent)
        h = {}
            ^ Space inside empty hash literal braces missing.
      RUBY
    end

    it 'auto-corrects missing space' do
      new_source = autocorrect_source('h = {}')
      expect(new_source).to eq('h = { }')
    end
  end

  it 'registers an offense for hashes with no spaces if so configured' do
    expect_offense(<<-RUBY.strip_indent)
      h = {a: 1, b: 2}
          ^ Space inside { missing.
                     ^ Space inside } missing.
      h = {a => 1}
          ^ Space inside { missing.
                 ^ Space inside } missing.
    RUBY
  end

  it 'registers an offense for correct + opposite' do
    expect_offense(<<-RUBY.strip_indent)
      h = { a: 1}
                ^ Space inside } missing.
    RUBY
  end

  it 'auto-corrects missing space' do
    new_source = autocorrect_source(<<-RUBY.strip_indent)
      h = {a: 1, b: 2}
      h = {a => 1 }
    RUBY
    expect(new_source).to eq(<<-RUBY.strip_indent)
      h = { a: 1, b: 2 }
      h = { a => 1 }
    RUBY
  end

  context 'when EnforcedStyle is no_space' do
    let(:cop_config) { { 'EnforcedStyle' => 'no_space' } }

    it 'registers an offense for hashes with spaces' do
      expect_offense(<<-RUBY.strip_indent)
        h = { a: 1, b: 2 }
             ^ Space inside { detected.
                        ^ Space inside } detected.
      RUBY
    end

    it 'registers an offense for opposite + correct' do
      expect_offense(<<-RUBY.strip_indent)
        h = {a: 1 }
                 ^ Space inside } detected.
      RUBY
    end

    it 'auto-corrects unwanted space' do
      new_source = autocorrect_source(<<-RUBY.strip_indent)
        h = { a: 1, b: 2 }
        h = {a => 1 }
      RUBY
      expect(new_source).to eq(<<-RUBY.strip_indent)
        h = {a: 1, b: 2}
        h = {a => 1}
      RUBY
    end

    it 'accepts hashes with no spaces' do
      expect_no_offenses(<<-RUBY.strip_indent)
        h = {a: 1, b: 2}
        h = {a => 1}
      RUBY
    end

    it 'accepts multiline hash' do
      expect_no_offenses(<<-RUBY.strip_indent)
        h = {
              a: 1,
              b: 2,
        }
      RUBY
    end

    it 'accepts multiline hash with comment' do
      expect_no_offenses(<<-RUBY.strip_indent)
        h = { # Comment
              a: 1,
              b: 2,
        }
      RUBY
    end
  end

  context 'when EnforcedStyle is compact' do
    let(:cop_config) { { 'EnforcedStyle' => 'compact' } }

    it "doesn't register an offense for non-nested hashes with spaces" do
      expect_no_offenses(<<-RUBY.strip_indent)
        h = { a: 1, b: 2 }
      RUBY
    end

    it 'registers an offense for nested hashes with spaces' do
      expect_offense(<<-RUBY.strip_indent)
        h = { a: { a: 1, b: 2 } }
                               ^ Space inside } detected.
      RUBY
    end

    it 'registers an offense for opposite + correct' do
      expect_offense(<<-RUBY.strip_indent)
        h = {a: 1 }
            ^ Space inside { missing.
      RUBY
    end

    it 'auto-corrects hashes with no space' do
      new_source = autocorrect_source(<<-RUBY.strip_indent)
        h = {a: 1, b: 2}
        h = {a => 1 }
      RUBY
      expect(new_source).to eq(<<-RUBY.strip_indent)
        h = { a: 1, b: 2 }
        h = { a => 1 }
      RUBY
    end

    it 'auto-corrects nested hashes with spaces' do
      new_source = autocorrect_source(<<-RUBY.strip_indent)
        h = { a: { a: 1, b: 2 } }
        h = {a => method { 1 } }
      RUBY
      expect(new_source).to eq(<<-RUBY.strip_indent)
        h = { a: { a: 1, b: 2 }}
        h = { a => method { 1 }}
      RUBY
    end

    it 'registers offenses for hashes with no spaces' do
      expect_offense(<<-RUBY.strip_indent)
        h = {a: 1, b: 2}
                       ^ Space inside } missing.
            ^ Space inside { missing.
        h = {a => 1}
                   ^ Space inside } missing.
            ^ Space inside { missing.
      RUBY
    end

    it 'accepts multiline hash' do
      expect_no_offenses(<<-RUBY.strip_indent)
        h = {
              a: 1,
              b: 2,
        }
      RUBY
    end

    it 'accepts multiline hash with comment' do
      expect_no_offenses(<<-RUBY.strip_indent)
        h = { # Comment
              a: 1,
              b: 2,
        }
      RUBY
    end
  end

  it 'accepts hashes with spaces by default' do
    expect_no_offenses(<<-RUBY.strip_indent)
      h = { a: 1, b: 2 }
      h = { a => 1 }
    RUBY
  end

  it 'accepts hash literals with no braces' do
    expect_no_offenses('x(a: b.c)')
  end

  it 'can handle interpolation in a braceless hash literal' do
    # A tricky special case where the closing brace of the
    # interpolation risks getting confused for a hash literal brace.
    expect_no_offenses('f(get: "#{x}")')
  end

  context 'on Hash[{ x: 1 } => [1]]' do
    # regression test; see GH issue 2436
    it 'does not register an offense' do
      expect_no_offenses('Hash[{ x: 1 } => [1]]')
    end
  end

  context 'on { key: "{" }' do
    # regression test; see GH issue 3958
    it 'does not register an offense' do
      expect_no_offenses('{ key: "{" }')
    end
  end
end
