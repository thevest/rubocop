# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Layout::SpaceInsideStringInterpolation, :config do
  subject(:cop) { described_class.new(config) }

  let(:irregular_source) do
    <<-'RUBY'.strip_indent.chomp
      "#{ var}"
      "#{var }"
      "#{   var   }"
      "#{var	}"
      "#{	var	}"
      "#{	var}"
      "#{ 	 var 	 	}"
    RUBY
  end

  shared_examples 'ill-formatted string interpolations' do
    let(:source_length) { source.count("\n") + 1 }

    it 'registers an offense for any irregular spacing inside the braces' do
      inspect_source(source)
      expect(cop.messages).to eq([expected_message] * source_length)
    end

    it 'auto-corrects spacing within a string interpolation' do
      new_source = autocorrect_source(source)
      expected_source = ([corrected_source] * source_length).join("\n")
      expect(new_source).to eq(expected_source)
    end
  end

  context 'when EnforcedStyle is no_space' do
    let(:cop_config) { { 'EnforcedStyle' => 'no_space' } }
    let(:expected_message) do
      'Space inside string interpolation detected.'
    end

    context 'for always ill-formatted string interpolations' do
      let(:source) { irregular_source }
      let(:corrected_source) { '"#{var}"' }

      it_behaves_like 'ill-formatted string interpolations'
    end

    context 'for "space" style formatted string interpolations' do
      let(:source) { '"#{ var }"' }
      let(:corrected_source) { '"#{var}"' }

      it_behaves_like 'ill-formatted string interpolations'
    end

    context 'for well-formatted string interpolations' do
      let(:source) do
        <<-'RUBY'.strip_indent.chomp
          "Variable is    #{var}      "
          "  Variable is  #{var}"
        RUBY
      end

      it 'does not register an offense for excess literal spacing' do
        expect_no_offenses(<<-'RUBY'.strip_indent)
          "Variable is    #{var}      "
          "  Variable is  #{var}"
        RUBY
      end

      it 'does not correct valid string interpolations' do
        new_source = autocorrect_source(source)
        expect(new_source).to eq(source)
      end
    end

    it 'accepts empty interpolation' do
      expect_no_offenses("\"\#{}\"")
    end
  end

  context 'when EnforcedStyle is space' do
    let(:cop_config) { { 'EnforcedStyle' => 'space' } }
    let(:expected_message) do
      'Missing space around string interpolation detected.'
    end

    context 'for always ill-formatted string interpolations' do
      let(:source) { irregular_source }
      let(:corrected_source) { '"#{ var }"' }

      it_behaves_like 'ill-formatted string interpolations'
    end

    context 'for "no_space" style formatted string interpolations' do
      let(:source) { '"#{var}"' }
      let(:corrected_source) { '"#{ var }"' }

      it_behaves_like 'ill-formatted string interpolations'
    end

    context 'for well-formatted string interpolations' do
      let(:source) do
        <<-'RUBY'.strip_indent.chomp
          "Variable is    #{ var }      "
          "  Variable is  #{ var }"
        RUBY
      end

      it 'does not register an offense for excess literal spacing' do
        expect_no_offenses(<<-'RUBY'.strip_indent)
          "Variable is    #{ var }      "
          "  Variable is  #{ var }"
        RUBY
      end

      it 'does not correct valid string interpolations' do
        new_source = autocorrect_source(source)
        expect(new_source).to eq(source)
      end
    end

    it 'accepts empty interpolation' do
      expect_no_offenses("\"\#{}\"")
    end
  end
end
