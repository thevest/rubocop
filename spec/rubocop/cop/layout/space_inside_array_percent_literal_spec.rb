# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Layout::SpaceInsideArrayPercentLiteral do
  subject(:cop) { described_class.new }

  let(:message) do
    'Use only a single space inside array percent literal.'
  end

  %w[i I w W].each do |type|
    [%w[{ }], %w[( )], %w([ ]), %w[! !]].each do |(ldelim, rdelim)|
      context "for #{type} type and #{[ldelim, rdelim]} delimiters" do
        define_method(:code_example) do |content|
          ['%', type, ldelim, content, rdelim].join
        end

        def expect_corrected(source, expected)
          expect(autocorrect_source(source)).to eq expected
        end

        it 'registers an offense for unnecessary spaces' do
          source = code_example('1   2')
          inspect_source(source)
          expect(cop.offenses.size).to eq(1)
          expect(cop.highlights).to eq(['   '])
          expect(cop.messages).to eq([message])
          expect_corrected(source, code_example('1 2'))
        end

        it 'registers an offense for multiple spaces between items' do
          source = code_example('1   2   3')
          inspect_source(source)
          expect(cop.offenses.size).to eq(2)
          expect_corrected(source, code_example('1 2 3'))
        end

        it 'accepts literals with escaped and additional spaces' do
          source = code_example('a\   b \ c')
          inspect_source(source)
          expect(cop.offenses.size).to eq(1)
          expect_corrected(source, code_example('a\  b \ c'))
        end

        it 'accepts literals without additional spaces' do
          expect_no_offenses(code_example('a b c'))
        end

        it 'accepts literals with escaped spaces' do
          expect_no_offenses(code_example('a\  b\ \  c'))
        end

        it 'accepts multi-line literals' do
          expect_no_offenses(<<-RUBY.strip_indent)
            %#{type}(
              a
              b
              c
            )
          RUBY
        end

        it 'accepts multi-line literals within a method' do
          expect_no_offenses(<<-RUBY.strip_indent)
            def foo
              %#{type}(
                a
                b
                c
              )
            end
          RUBY
        end

        it 'accepts newlines and additional following alignment spaces' do
          expect_no_offenses(<<-RUBY.strip_indent)
            %#{type}(a b
               c)
          RUBY
        end
      end
    end
  end

  it 'accepts non array percent literals' do
    expect_no_offenses('%q( a  b c )')
  end
end
