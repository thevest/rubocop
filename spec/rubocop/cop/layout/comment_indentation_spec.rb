# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Layout::CommentIndentation do
  subject(:cop) { described_class.new(config) }

  let(:config) do
    RuboCop::Config
      .new('Layout/IndentationWidth' => { 'Width' => indentation_width })
  end
  let(:indentation_width) { 2 }

  context 'on outer level' do
    it 'accepts a correctly indented comment' do
      expect_no_offenses('# comment')
    end

    it 'accepts a comment that follows code' do
      expect_no_offenses('hello # comment')
    end

    it 'accepts a documentation comment' do
      expect_offense(<<-RUBY.strip_indent)
        =begin
        Doc comment
        =end
          hello
         #
         ^ Incorrect indentation detected (column 1 instead of 0).
        hi
      RUBY
    end

    it 'registers an offense for an incorrectly indented (1) comment' do
      expect_offense(<<-RUBY.strip_margin('|'))
        | # comment
        | ^^^^^^^^^ Incorrect indentation detected (column 1 instead of 0).
      RUBY
    end

    it 'registers an offense for an incorrectly indented (2) comment' do
      expect_offense(<<-RUBY.strip_margin('|'))
        |  # comment
        |  ^^^^^^^^^ Incorrect indentation detected (column 2 instead of 0).
      RUBY
    end

    it 'registers an offense for each incorrectly indented comment' do
      expect_offense(<<-RUBY.strip_indent)
        # a
        ^^^ Incorrect indentation detected (column 0 instead of 2).
          # b
          ^^^ Incorrect indentation detected (column 2 instead of 4).
            # c
            ^^^ Incorrect indentation detected (column 4 instead of 0).
        # d
        def test; end
      RUBY
    end
  end

  it 'registers offenses before __RUBY__ but not after' do
    expect_offense(<<-RUBY.strip_indent)
       #
       ^ Incorrect indentation detected (column 1 instead of 0).
      __END__
        #
    RUBY
  end

  context 'around program structure keywords' do
    it 'accepts correctly indented comments' do
      expect_no_offenses(<<-RUBY.strip_indent)
        #
        def m
          #
          if a
            #
            b
          # this is accepted
          elsif aa
            # this is accepted
          else
            #
          end
          #
          case a
          # this is accepted
          when 0
            #
            b
          end
          # this is accepted
        rescue
        # this is accepted
        ensure
          #
        end
        #
      RUBY
    end

    context 'with a blank line following the comment' do
      it 'accepts a correctly indented comment' do
        expect_no_offenses(<<-RUBY.strip_indent)
          def m
            # comment

          end
        RUBY
      end
    end
  end

  context 'near various kinds of brackets' do
    it 'accepts correctly indented comments' do
      expect_no_offenses(<<-RUBY.strip_indent)
        #
        a = {
          #
          x: [
            1
            #
          ],
          #
          y: func(
            1
            #
          )
          #
        }
        #
      RUBY
    end

    it 'is unaffected by closing bracket that does not begin a line' do
      expect_no_offenses(<<-RUBY.strip_indent)
        #
        result = []
      RUBY
    end
  end

  it 'auto-corrects' do
    new_source = autocorrect_source(<<-RUBY.strip_indent)
       # comment
       # comment
       # comment
      hash1 = { a: 0,
           # comment
                bb: 1,
                ccc: 2 }
        if a
        #
          b
        # this is accepted
        elsif aa
          # so is this
        elsif bb
      #
        else
         #
        end
        case a
        # this is accepted
        when 0
          # so is this
        when 1
           #
          b
        end
    RUBY
    expect(new_source).to eq(<<-RUBY.strip_indent)
      # comment
      # comment
      # comment
      hash1 = { a: 0,
                # comment
                bb: 1,
                ccc: 2 }
        if a
          #
          b
        # this is accepted
        elsif aa
          # so is this
        elsif bb
        #
        else
          #
        end
        case a
        # this is accepted
        when 0
          # so is this
        when 1
          #
          b
        end
    RUBY
  end
end
