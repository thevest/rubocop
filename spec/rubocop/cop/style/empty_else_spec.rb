# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::EmptyElse do
  subject(:cop) { described_class.new(config) }

  let(:missing_else_config) { {} }

  shared_examples 'auto-correct' do |keyword|
    context 'MissingElse is disabled' do
      it 'does auto-correction' do
        expect(autocorrect_source(source)).to eq(corrected_source)
      end
    end

    %w[both if case].each do |missing_else_style|
      context "MissingElse is #{missing_else_style}" do
        let(:missing_else_config) do
          { 'Enabled' => true,
            'EnforcedStyle' => missing_else_style }
        end

        if ['both', keyword].include? missing_else_style
          it 'does not auto-correct' do
            expect(autocorrect_source(source)).to eq(source)
            expect(cop.offenses.map(&:corrected?)).to eq [false]
          end
        else
          it 'does auto-correction' do
            expect(autocorrect_source(source)).to eq(corrected_source)
          end
        end
      end
    end
  end

  shared_examples_for 'offense registration' do
    it 'registers an offense with correct message' do
      inspect_source(source)
      expect(cop.messages).to eq(['Redundant `else`-clause.'])
    end

    it 'registers an offense with correct location' do
      inspect_source(source)
      expect(cop.highlights).to eq(['else'])
    end
  end

  context 'configured to warn on empty else' do
    let(:config) do
      RuboCop::Config.new('Style/EmptyElse' => {
                            'EnforcedStyle' => 'empty',
                            'SupportedStyles' => %w[empty nil both]
                          },
                          'Style/MissingElse' => missing_else_config)
    end

    context 'given an if-statement' do
      context 'with a completely empty else-clause' do
        context 'using semicolons' do
          let(:source) { 'if a; foo else end' }
          let(:corrected_source) { 'if a; foo end' }

          it_behaves_like 'offense registration'
          it_behaves_like 'auto-correct', 'if'
        end

        context 'not using semicolons' do
          let(:source) do
            <<-RUBY.strip_indent
              if a
                foo
              else
              end
            RUBY
          end
          let(:corrected_source) do
            <<-RUBY.strip_indent
              if a
                foo
              end
            RUBY
          end

          it_behaves_like 'offense registration'
          it_behaves_like 'auto-correct', 'if'
        end
      end

      context 'with an else-clause containing only the literal nil' do
        it "doesn't register an offense" do
          expect_no_offenses('if a; foo elsif b; bar else nil end')
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('if cond; foo else bar; nil end')
        end
      end

      context 'with no else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('if cond; foo end')
        end
      end

      context 'in an if-statement' do
        let(:source) { <<-RUBY.strip_indent }
          if cond
            if cond2
              something
            else
            end
          end
        RUBY
        let(:corrected_source) { <<-RUBY.strip_indent }
          if cond
            if cond2
              something
            end
          end
        RUBY

        it_behaves_like 'auto-correct', 'if'
        it_behaves_like 'offense registration'
      end

      context 'with an empty comment' do
        let(:source) { <<-RUBY.strip_indent }
          if cond
            something
          else
            # TODO
          end
        RUBY
        let(:corrected_source) { <<-RUBY.strip_indent }
          if cond
            something
          else
            # TODO
          end
        RUBY

        it_behaves_like 'auto-correct', 'if'
        it_behaves_like 'offense registration'
      end
    end

    context 'given an unless-statement' do
      context 'with a completely empty else-clause' do
        let(:source) { 'unless cond; foo else end' }
        let(:corrected_source) { 'unless cond; foo end' }

        it_behaves_like 'offense registration'
        it_behaves_like 'auto-correct', 'if'
      end

      context 'with an else-clause containing only the literal nil' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo else nil end')
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo else bar; nil end')
        end
      end

      context 'with no else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo end')
        end
      end
    end

    context 'given a case statement' do
      context 'with a completely empty else-clause' do
        let(:source) { 'case v; when a; foo else end' }
        let(:corrected_source) { 'case v; when a; foo end' }

        it_behaves_like 'offense registration'
        it_behaves_like 'auto-correct', 'case'
      end

      context 'with an else-clause containing only the literal nil' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo; when b; bar; else nil end')
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo; else b; nil end')
        end
      end

      context 'with no else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo; when b; bar; end')
        end
      end
    end
  end

  context 'configured to warn on nil in else' do
    let(:config) do
      RuboCop::Config.new('Style/EmptyElse' => {
                            'EnforcedStyle' => 'nil',
                            'SupportedStyles' => %w[empty nil both]
                          },
                          'Style/MissingElse' => missing_else_config)
    end

    context 'given an if-statement' do
      context 'with a completely empty else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('if a; foo else end')
        end
      end

      context 'with an else-clause containing only the literal nil' do
        context 'when standalone' do
          let(:source) do
            <<-RUBY.strip_indent
              if a
                foo
              elsif b
                bar
              else
                nil
              end
            RUBY
          end

          let(:corrected_source) do
            <<-RUBY.strip_indent
              if a
                foo
              elsif b
                bar
              end
            RUBY
          end

          it_behaves_like 'offense registration'
          it_behaves_like 'auto-correct', 'if'
        end

        context 'when the result is assigned to a variable' do
          let(:source) do
            ['foobar = if a',
             '           foo',
             '         elsif b',
             '           bar',
             '         else',
             '           nil',
             '         end'].join("\n")
          end

          let(:corrected_source) do
            ['foobar = if a',
             '           foo',
             '         elsif b',
             '           bar',
             '         end'].join("\n")
          end

          it_behaves_like 'offense registration'
          it_behaves_like 'auto-correct', 'if'
        end
      end

      context 'with an else-clause containing only the literal nil ' \
              'using semicolons' do
        context 'with one elsif' do
          let(:source) { 'if a; foo elsif b; bar else nil end' }
          let(:corrected_source) { 'if a; foo elsif b; bar end' }

          it_behaves_like 'offense registration'
          it_behaves_like 'auto-correct', 'if'
        end

        context 'with multiple elsifs' do
          let(:source) { 'if a; foo elsif b; bar; elsif c; bar else nil end' }
          let(:corrected_source) { 'if a; foo elsif b; bar; elsif c; bar end' }

          it_behaves_like 'offense registration'
          it_behaves_like 'auto-correct', 'if'
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('if cond; foo else bar; nil end')
        end
      end

      context 'with no else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('if cond; foo end')
        end
      end
    end

    context 'given an unless-statement' do
      context 'with a completely empty else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo else end')
        end
      end

      context 'with an else-clause containing only the literal nil' do
        let(:source) { 'unless cond; foo else nil end' }
        let(:corrected_source) { 'unless cond; foo end' }

        it_behaves_like 'offense registration'
        it_behaves_like 'auto-correct', 'if'
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo else bar; nil end')
        end
      end

      context 'with no else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo end')
        end
      end
    end

    context 'given a case statement' do
      context 'with a completely empty else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo else end')
        end
      end

      context 'with an else-clause containing only the literal nil' do
        context 'using semicolons' do
          let(:source) { 'case v; when a; foo; when b; bar; else nil end' }
          let(:corrected_source) { 'case v; when a; foo; when b; bar; end' }

          it_behaves_like 'offense registration'
          it_behaves_like 'auto-correct', 'case'
        end

        context 'when the result is assigned to a variable' do
          let(:source) do
            ['foobar = case v',
             '         when a',
             '           foo',
             '         when b',
             '           bar',
             '         else',
             '           nil',
             '         end'].join("\n")
          end

          let(:corrected_source) do
            ['foobar = case v',
             '         when a',
             '           foo',
             '         when b',
             '           bar',
             '         end'].join("\n")
          end

          it_behaves_like 'offense registration'
          it_behaves_like 'auto-correct', 'case'
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo; else b; nil end')
        end
      end

      context 'with no else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo; when b; bar; end')
        end
      end
    end
  end

  context 'configured to warn on empty else and nil in else' do
    let(:config) do
      RuboCop::Config.new('Style/EmptyElse' => {
                            'EnforcedStyle' => 'both',
                            'SupportedStyles' => %w[empty nil both]
                          },
                          'Style/MissingElse' => missing_else_config)
    end

    context 'given an if-statement' do
      context 'with a completely empty else-clause' do
        let(:source) { 'if a; foo else end' }
        let(:corrected_source) { 'if a; foo end' }

        it_behaves_like 'offense registration'
        it_behaves_like 'auto-correct', 'if'
      end

      context 'with an else-clause containing only the literal nil' do
        context 'with one elsif' do
          let(:source) { 'if a; foo elsif b; bar else nil end' }
          let(:corrected_source) { 'if a; foo elsif b; bar end' }

          it_behaves_like 'offense registration'
          it_behaves_like 'auto-correct', 'if'
        end

        context 'with multiple elsifs' do
          let(:source) { 'if a; foo elsif b; bar; elsif c; bar else nil end' }
          let(:corrected_source) { 'if a; foo elsif b; bar; elsif c; bar end' }

          it_behaves_like 'offense registration'
          it_behaves_like 'auto-correct', 'if'
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('if cond; foo else bar; nil end')
        end
      end

      context 'with no else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('if cond; foo end')
        end
      end
    end

    context 'given an unless-statement' do
      context 'with a completely empty else-clause' do
        let(:source) { 'unless cond; foo else end' }
        let(:corrected_source) { 'unless cond; foo end' }

        it_behaves_like 'offense registration'
        it_behaves_like 'auto-correct', 'if'
      end

      context 'with an else-clause containing only the literal nil' do
        let(:source) { 'unless cond; foo else nil end' }
        let(:corrected_source) { 'unless cond; foo end' }

        it_behaves_like 'offense registration'
        it_behaves_like 'auto-correct', 'if'
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo else bar; nil end')
        end
      end

      context 'with no else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo end')
        end
      end
    end

    context 'given a case statement' do
      context 'with a completely empty else-clause' do
        let(:source) { 'case v; when a; foo else end' }
        let(:corrected_source) { 'case v; when a; foo end' }

        it_behaves_like 'offense registration'
        it_behaves_like 'auto-correct', 'case'
      end

      context 'with an else-clause containing only the literal nil' do
        let(:source) { 'case v; when a; foo; when b; bar; else nil end' }
        let(:corrected_source) { 'case v; when a; foo; when b; bar; end' }

        it_behaves_like 'offense registration'
        it_behaves_like 'auto-correct', 'case'
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo; else b; nil end')
        end
      end

      context 'with no else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo; when b; bar; end')
        end
      end
    end
  end

  context 'with nested if and case statement' do
    let(:config) do
      RuboCop::Config.new('Style/EmptyElse' => {
                            'EnforcedStyle' => 'nil',
                            'SupportedStyles' => %w[empty nil both]
                          },
                          'Style/MissingElse' => missing_else_config)
    end

    let(:source) do
      <<-RUBY.strip_indent
        def foo
          if @params
            case @params[:x]
            when :a
              :b
            else
              nil
            end
          else
            :c
          end
        end
      RUBY
    end

    let(:corrected_source) do
      <<-RUBY.strip_indent
        def foo
          if @params
            case @params[:x]
            when :a
              :b
            end
          else
            :c
          end
        end
      RUBY
    end

    it_behaves_like 'offense registration'
    it_behaves_like 'auto-correct', 'case'
  end
end
