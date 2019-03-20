# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Layout::SpaceInsideBlockBraces, :config do
  SUPPORTED_STYLES = %w[space no_space].freeze

  subject(:cop) { described_class.new(config) }

  let(:cop_config) do
    {
      'EnforcedStyle' => 'space',
      'SupportedStyles' => SUPPORTED_STYLES,
      'SpaceBeforeBlockParameters' => true
    }
  end

  context 'with space inside empty braces not allowed' do
    let(:cop_config) { { 'EnforcedStyleForEmptyBraces' => 'no_space' } }

    it 'accepts empty braces with no space inside' do
      expect_no_offenses('each {}')
    end

    it 'accepts braces with something inside' do
      expect_no_offenses('each { "f" }')
    end

    it 'accepts multiline braces with content' do
      expect_no_offenses(<<-RUBY.strip_indent)
        each { %(
        ) }
      RUBY
    end

    it 'accepts empty braces with comment and line break inside' do
      expect_no_offenses(<<-RUBY.strip_indent)
        each { # Comment
        }
      RUBY
    end

    it 'registers an offense for empty braces with line break inside' do
      inspect_source(<<-RUBY.strip_margin('|'))
        |  each {
        |  }
      RUBY
      expect(cop.messages).to eq(['Space inside empty braces detected.'])
      expect(cop.highlights).to eq(["\n  "])
    end

    it 'registers an offense for empty braces with space inside' do
      expect_offense(<<-RUBY.strip_indent)
        each { }
              ^ Space inside empty braces detected.
      RUBY
    end

    it 'auto-corrects unwanted space' do
      new_source = autocorrect_source('each { }')
      expect(new_source).to eq('each {}')
    end

    it 'does not auto-correct when braces are not empty' do
      old_source = <<-RUBY
        a {
          b
        }
      RUBY
      new_source = autocorrect_source(old_source)
      expect(new_source).to eq(old_source)
    end
  end

  context 'with space inside empty braces allowed' do
    let(:cop_config) { { 'EnforcedStyleForEmptyBraces' => 'space' } }

    it 'accepts empty braces with space inside' do
      expect_no_offenses('each { }')
    end

    it 'registers an offense for empty braces with no space inside' do
      expect_offense(<<-RUBY.strip_indent)
        each {}
             ^^ Space missing inside empty braces.
      RUBY
    end

    it 'auto-corrects missing space' do
      new_source = autocorrect_source('each {}')
      expect(new_source).to eq('each { }')
    end
  end

  context 'with invalid value for EnforcedStyleForEmptyBraces' do
    let(:cop_config) { { 'EnforcedStyleForEmptyBraces' => 'unknown' } }

    it 'fails with an error' do
      expect { inspect_source('each { }') }
        .to raise_error('Unknown EnforcedStyleForEmptyBraces selected!')
    end
  end

  it 'accepts braces surrounded by spaces' do
    expect_no_offenses('each { puts }')
  end

  it 'accepts left brace without outer space' do
    expect_no_offenses('each{ puts }')
  end

  it 'registers an offense for left brace without inner space' do
    expect_offense(<<-RUBY.strip_indent)
      each {puts }
            ^ Space missing inside {.
    RUBY
  end

  it 'registers an offense for right brace without inner space' do
    expect_offense(<<-RUBY.strip_indent)
      each { puts}
                 ^ Space missing inside }.
    RUBY
  end

  it 'registers offenses for both braces without inner space' do
    expect_offense(<<-RUBY.strip_indent)
      a {}
      b { }
         ^ Space inside empty braces detected.
      each {puts}
            ^ Space missing inside {.
                ^ Space missing inside }.
    RUBY
  end

  it 'auto-corrects missing space' do
    new_source = autocorrect_source('each {puts}')
    expect(new_source).to eq('each { puts }')
  end

  context 'with passed in parameters' do
    context 'for single-line blocks' do
      it 'accepts left brace with inner space' do
        expect_no_offenses('each { |x| puts }')
      end

      it 'registers an offense for left brace without inner space' do
        expect_offense(<<-RUBY.strip_indent)
          each {|x| puts }
               ^^ Space between { and | missing.
        RUBY
      end
    end

    context 'for multi-line blocks' do
      it 'accepts left brace with inner space' do
        expect_no_offenses(<<-RUBY.strip_indent)
          each { |x|
            puts
          }
        RUBY
      end

      it 'registers an offense for left brace without inner space' do
        expect_offense(<<-RUBY.strip_indent)
          each {|x|
               ^^ Space between { and | missing.
            puts
          }
        RUBY
      end

      it 'auto-corrects missing space' do
        new_source = autocorrect_source(<<-SOURCE)
          each {|x|
            puts
          }
        SOURCE

        expect(new_source).to eq(<<-NEW_SOURCE)
          each { |x|
            puts
          }
        NEW_SOURCE
      end
    end

    it 'accepts new lambda syntax' do
      expect_no_offenses('->(x) { x }')
    end

    it 'auto-corrects missing space' do
      new_source = autocorrect_source('each {|x| puts }')
      expect(new_source).to eq('each { |x| puts }')
    end

    context 'and BlockDelimiters cop enabled' do
      let(:config) do
        RuboCop::Config.new('Style/BlockDelimiters' => { 'Enabled' => true },
                            'Layout/SpaceInsideBlockBraces' => cop_config)
      end

      it 'does auto-correction for single-line blocks' do
        new_source = autocorrect_source('each {|x| puts}')
        expect(new_source).to eq('each { |x| puts }')
      end

      it 'does auto-correction for multi-line blocks' do
        old_source = <<-RUBY.strip_indent
          each {|x|
            puts
          }
        RUBY
        new_source = autocorrect_source(old_source)
        expect(new_source).to eq(<<-RUBY.strip_indent)
          each { |x|
            puts
          }
        RUBY
      end
    end

    context 'and space before block parameters not allowed' do
      let(:cop_config) do
        {
          'EnforcedStyle' => 'space',
          'SupportedStyles' => SUPPORTED_STYLES,
          'SpaceBeforeBlockParameters' => false
        }
      end

      it 'registers an offense for left brace with inner space' do
        expect_offense(<<-RUBY.strip_indent)
          each { |x| puts }
                ^ Space between { and | detected.
        RUBY
      end

      it 'accepts new lambda syntax' do
        expect_no_offenses('->(x) { x }')
      end

      it 'auto-corrects unwanted space' do
        new_source = autocorrect_source('each { |x| puts }')
        expect(new_source).to eq('each {|x| puts }')
      end

      it 'accepts left brace without inner space' do
        expect_no_offenses('each {|x| puts }')
      end
    end
  end

  context 'configured with no_space' do
    let(:cop_config) do
      {
        'EnforcedStyle' => 'no_space',
        'SupportedStyles' => SUPPORTED_STYLES,
        'SpaceBeforeBlockParameters' => true
      }
    end

    it 'accepts braces without spaces inside' do
      expect_no_offenses('each {puts}')
    end

    it 'registers an offense for left brace with inner space' do
      expect_offense(<<-RUBY.strip_indent)
        each { puts}
              ^ Space inside { detected.
      RUBY
    end

    it 'registers an offense for right brace with inner space' do
      expect_offense(<<-RUBY.strip_indent)
        each {puts }
                  ^ Space inside } detected.
      RUBY
    end

    it 'accepts left brace without outer space' do
      expect_no_offenses('each{puts}')
    end

    it 'auto-corrects unwanted space' do
      new_source = autocorrect_source('each{ puts }')
      expect(new_source).to eq('each{puts}')
    end

    context 'with passed in parameters' do
      context 'and space before block parameters allowed' do
        it 'accepts left brace with inner space' do
          expect_no_offenses('each { |x| puts}')
        end

        it 'registers an offense for left brace without inner space' do
          expect_offense(<<-RUBY.strip_indent)
            each {|x| puts}
                 ^^ Space between { and | missing.
          RUBY
        end

        it 'accepts new lambda syntax' do
          expect_no_offenses('->(x) {x}')
        end

        it 'auto-corrects missing space' do
          new_source = autocorrect_source('each {|x| puts}')
          expect(new_source).to eq('each { |x| puts}')
        end
      end

      context 'and space before block parameters not allowed' do
        let(:cop_config) do
          {
            'EnforcedStyle' => 'no_space',
            'SupportedStyles' => SUPPORTED_STYLES,
            'SpaceBeforeBlockParameters' => false
          }
        end

        it 'registers an offense for left brace with inner space' do
          expect_offense(<<-RUBY.strip_indent)
            each { |x| puts}
                  ^ Space between { and | detected.
          RUBY
        end

        it 'accepts new lambda syntax' do
          expect_no_offenses('->(x) {x}')
        end

        it 'auto-corrects unwanted space' do
          new_source = autocorrect_source('each { |x| puts}')
          expect(new_source).to eq('each {|x| puts}')
        end
      end
    end
  end
end
