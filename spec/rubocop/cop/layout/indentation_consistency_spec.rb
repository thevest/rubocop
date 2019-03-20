# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Layout::IndentationConsistency, :config do
  subject(:cop) { described_class.new(config) }

  let(:cop_config) { { 'EnforcedStyle' => 'normal' } }

  context 'with top-level code' do
    it 'accepts an empty expression string interpolation' do
      expect_no_offenses(<<-'RUBY'.strip_indent)
        "#{}"
      RUBY
    end
  end

  context 'with if statement' do
    it 'registers an offense for bad indentation in an if body' do
      expect_offense(<<-RUBY.strip_indent)
        if cond
         func
          func
          ^^^^ Inconsistent indentation detected.
        end
      RUBY
    end

    it 'registers an offense for bad indentation in an else body' do
      expect_offense(<<-RUBY.strip_indent)
        if cond
          func1
        else
         func2
          func2
          ^^^^^ Inconsistent indentation detected.
        end
      RUBY
    end

    it 'registers an offense for bad indentation in an elsif body' do
      expect_offense(<<-RUBY.strip_indent)
        if a1
          b1
        elsif a2
         b2
        b3
        ^^ Inconsistent indentation detected.
        else
          c
        end
      RUBY
    end

    it 'autocorrects bad indentation' do
      corrected = autocorrect_source(<<-RUBY.strip_indent)
        if a1
           b1
        elsif a2
         b2
          b3
        else
            c
        end
      RUBY
      expect(corrected).to eq <<-RUBY.strip_indent
        if a1
           b1
        elsif a2
         b2
         b3
        else
            c
        end
      RUBY
    end

    it 'accepts a one line if statement' do
      expect_no_offenses('if cond then func1 else func2 end')
    end

    it 'accepts a correctly aligned if/elsif/else/end' do
      expect_no_offenses(<<-RUBY.strip_indent)
        if a1
          b1
        elsif a2
          b2
        else
          c
        end
      RUBY
    end

    it 'accepts if/elsif/else/end laid out as a table' do
      expect_no_offenses(<<-RUBY.strip_indent)
        if    @io == $stdout then str << "$stdout"
        elsif @io == $stdin  then str << "$stdin"
        elsif @io == $stderr then str << "$stderr"
        else                      str << @io.class.to_s
        end
      RUBY
    end

    it 'accepts if/then/else/end laid out as another table' do
      expect_no_offenses(<<-RUBY.strip_indent)
        if File.exist?('config.save')
        then ConfigTable.load
        else ConfigTable.new
        end
      RUBY
    end

    it 'accepts if/elsif/else/end with fullwidth characters' do
      expect_no_offenses(<<-RUBY.strip_indent)
        p 'Ｒｕｂｙ', if a then b
                                c
                      end
      RUBY
    end

    it 'accepts an empty if' do
      expect_no_offenses(<<-RUBY.strip_indent)
        if a
        else
        end
      RUBY
    end

    it 'accepts an if in assignment with end aligned with variable' do
      expect_no_offenses(<<-RUBY.strip_indent)
        var = if a
          0
        end
        @var = if a
          0
        end
        $var = if a
          0
        end
        var ||= if a
          0
        end
        var &&= if a
          0
        end
        var -= if a
          0
        end
        VAR = if a
          0
        end
      RUBY
    end

    it 'accepts an if/else in assignment with end aligned with variable' do
      expect_no_offenses(<<-RUBY.strip_indent)
        var = if a
          0
        else
          1
        end
      RUBY
    end

    it 'accepts an if/else in assignment with end aligned with variable ' \
       'and chaining after the end' do
      expect_no_offenses(<<-RUBY.strip_indent)
        var = if a
          0
        else
          1
        end.abc.join("")
      RUBY
    end

    it 'accepts an if/else in assignment with end aligned with variable ' \
       'and chaining with a block after the end' do
      expect_no_offenses(<<-RUBY.strip_indent)
        var = if a
          0
        else
          1
        end.abc.tap {}
      RUBY
    end

    it 'accepts an if in assignment with end aligned with if' do
      expect_no_offenses(<<-RUBY.strip_indent)
        var = if a
                0
              end
      RUBY
    end

    it 'accepts an if/else in assignment with end aligned with if' do
      expect_no_offenses(<<-RUBY.strip_indent)
        var = if a
                0
              else
                1
              end
      RUBY
    end

    it 'accepts an if/else in assignment on next line with end aligned ' \
       'with if' do
      expect_no_offenses(<<-RUBY.strip_indent)
        var =
          if a
            0
          else
            1
          end
      RUBY
    end

    it 'accepts an if/else branches with rescue clauses' do
      # Because of how the rescue clauses come out of Parser, these are
      # special and need to be tested.
      expect_no_offenses(<<-RUBY.strip_indent)
        if a
          a rescue nil
        else
          a rescue nil
        end
      RUBY
    end
  end

  context 'with unless' do
    it 'registers an offense for bad indentation in an unless body' do
      expect_offense(<<-RUBY.strip_indent)
        unless cond
         func
          func
          ^^^^ Inconsistent indentation detected.
        end
      RUBY
    end

    it 'accepts an empty unless' do
      expect_no_offenses(<<-RUBY.strip_indent)
        unless a
        else
        end
      RUBY
    end
  end

  context 'with case' do
    it 'registers an offense for bad indentation in a case/when body' do
      expect_offense(<<-RUBY.strip_indent)
        case a
        when b
         c
            d
            ^ Inconsistent indentation detected.
        end
      RUBY
    end

    it 'registers an offense for bad indentation in a case/else body' do
      expect_offense(<<-RUBY.strip_indent)
        case a
        when b
          c
        when d
          e
        else
           f
          g
          ^ Inconsistent indentation detected.
        end
      RUBY
    end

    it 'accepts correctly indented case/when/else' do
      expect_no_offenses(<<-RUBY.strip_indent)
        case a
        when b
          c
          c
        when d
        else
          f
        end
      RUBY
    end

    it 'accepts case/when/else laid out as a table' do
      expect_no_offenses(<<-RUBY.strip_indent)
        case sexp.loc.keyword.source
        when 'if'     then cond, body, _else = *sexp
        when 'unless' then cond, _else, body = *sexp
        else               cond, body = *sexp
        end
      RUBY
    end

    it 'accepts case/when/else with then beginning a line' do
      expect_no_offenses(<<-RUBY.strip_indent)
        case sexp.loc.keyword.source
        when 'if'
        then cond, body, _else = *sexp
        end
      RUBY
    end

    it 'accepts indented when/else plus indented body' do
      # "Indent when as deep as case" is the job of another cop.
      expect_no_offenses(<<-RUBY.strip_indent)
        case code_type
          when 'ruby', 'sql', 'plain'
            code_type
          when 'erb'
            'ruby; html-script: true'
          when "html"
            'xml'
          else
            'plain'
        end
      RUBY
    end
  end

  context 'with while/until' do
    it 'registers an offense for bad indentation in a while body' do
      expect_offense(<<-RUBY.strip_indent)
        while cond
         func
          func
          ^^^^ Inconsistent indentation detected.
        end
      RUBY
    end

    it 'registers an offense for bad indentation in begin/end/while' do
      expect_offense(<<-RUBY.strip_indent)
        something = begin
         func1
           func2
           ^^^^^ Inconsistent indentation detected.
        end while cond
      RUBY
    end

    it 'registers an offense for bad indentation in an until body' do
      expect_offense(<<-RUBY.strip_indent)
        until cond
         func
          func
          ^^^^ Inconsistent indentation detected.
        end
      RUBY
    end

    it 'accepts an empty while' do
      expect_no_offenses(<<-RUBY.strip_indent)
        while a
        end
      RUBY
    end
  end

  context 'with for' do
    it 'registers an offense for bad indentation in a for body' do
      expect_offense(<<-RUBY.strip_indent)
        for var in 1..10
         func
        func
        ^^^^ Inconsistent indentation detected.
        end
      RUBY
    end

    it 'accepts an empty for' do
      expect_no_offenses(<<-RUBY.strip_indent)
        for var in 1..10
        end
      RUBY
    end
  end

  context 'with def/defs' do
    it 'registers an offense for bad indentation in a def body' do
      expect_offense(<<-RUBY.strip_indent)
        def test
            func1
             func2
             ^^^^^ Inconsistent indentation detected.
        end
      RUBY
    end

    it 'registers an offense for bad indentation in a defs body' do
      expect_offense(<<-RUBY.strip_indent)
        def self.test
           func
            func
            ^^^^ Inconsistent indentation detected.
        end
      RUBY
    end

    it 'accepts an empty def body' do
      expect_no_offenses(<<-RUBY.strip_indent)
        def test
        end
      RUBY
    end

    it 'accepts an empty defs body' do
      expect_no_offenses(<<-RUBY.strip_indent)
        def self.test
        end
      RUBY
    end
  end

  context 'with class' do
    context 'with rails style configured' do
      let(:cop_config) { { 'EnforcedStyle' => 'rails' } }

      it 'accepts different indentation in different visibility sections' do
        expect_no_offenses(<<-RUBY.strip_indent)
          class Cat
            def meow
              puts('Meow!')
            end

            protected

              def can_we_be_friends?(another_cat)
                # some logic
              end

              def related_to?(another_cat)
                # some logic
              end

            private

                        # Here we go back an indentation level again. This is a
                        # violation of the Rails style, but it's not for this
                        # cop to report. Layout/IndentationWidth will handle it.
            def meow_at_3am?
              rand < 0.8
            end

                        # As long as the indentation of this method is
                        # consistent with that of the last one, we're fine.
            def meow_at_4am?
              rand < 0.8
            end
          end
        RUBY
      end
    end

    context 'with normal style configured' do
      it 'registers an offense for bad indentation in a class body' do
        expect_offense(<<-RUBY.strip_indent)
          class Test
              def func1
              end
            def func2
            ^^^^^^^^^ Inconsistent indentation detected.
            end
          end
        RUBY
      end

      it 'accepts an empty class body' do
        expect_no_offenses(<<-RUBY.strip_indent)
          class Test
          end
        RUBY
      end

      it 'accepts indented public, protected, and private' do
        expect_no_offenses(<<-RUBY.strip_indent)
          class Test
            public

            def e
            end

            protected

            def f
            end

            private

            def g
            end
          end
        RUBY
      end

      it 'registers an offense for bad indentation in def but not for ' \
         'outdented public, protected, and private' do
        expect_offense(<<-RUBY.strip_indent)
          class Test
          public

            def e
            end

          protected

            def f
            end

          private

           def g
           ^^^^^ Inconsistent indentation detected.
           end
          end
        RUBY
      end
    end
  end

  context 'with module' do
    it 'registers an offense for bad indentation in a module body' do
      expect_offense(<<-RUBY.strip_indent)
        module Test
            def func1
            end
             def func2
             ^^^^^^^^^ Inconsistent indentation detected.
             end
        end
      RUBY
    end

    it 'accepts an empty module body' do
      expect_no_offenses(<<-RUBY.strip_indent)
        module Test
        end
      RUBY
    end

    it 'registers an offense for bad indentation of private methods' do
      expect_offense(<<-RUBY.strip_indent)
        module Test
          def pub
          end
          private
            def priv
            ^^^^^^^^ Inconsistent indentation detected.
            end
        end
      RUBY
    end

    context 'even when there are no public methods' do
      it 'still registers an offense for bad indentation of private methods' do
        expect_offense(<<-RUBY.strip_indent)
          module Test
            private
              def priv
              ^^^^^^^^ Inconsistent indentation detected.
              end
          end
        RUBY
      end
    end
  end

  context 'with block' do
    it 'registers an offense for bad indentation in a do/end body' do
      expect_offense(<<-RUBY.strip_indent)
        a = func do
         b
          c
          ^ Inconsistent indentation detected.
        end
      RUBY
    end

    it 'registers an offense for bad indentation in a {} body' do
      expect_offense(<<-RUBY.strip_indent)
        func {
           b
          c
          ^ Inconsistent indentation detected.
        }
      RUBY
    end

    it 'accepts a correctly indented block body' do
      expect_no_offenses(<<-RUBY.strip_indent)
        a = func do
          b
          c
        end
      RUBY
    end

    it 'accepts an empty block body' do
      expect_no_offenses(<<-RUBY.strip_indent)
        a = func do
        end
      RUBY
    end

    it 'does not auto-correct an offense within another offense' do
      corrected = autocorrect_source(<<-RUBY.strip_indent)
        require 'spec_helper'
        describe ArticlesController do
          render_views
            describe "GET \'index\'" do
                    it "returns success" do
                    end
                describe "admin user" do
                     before(:each) do
                    end
                end
            end
        end
      RUBY
      expect(cop.offenses.map(&:line)).to eq [4, 7] # Two offenses are found.

      # The offense on line 4 is corrected, affecting lines 4 to 11.
      expect(corrected).to eq <<-RUBY.strip_indent
        require 'spec_helper'
        describe ArticlesController do
          render_views
          describe \"GET 'index'\" do
                  it "returns success" do
                  end
              describe "admin user" do
                   before(:each) do
                  end
              end
          end
        end
      RUBY
    end
  end
end
