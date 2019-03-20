# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Layout::EmptyLinesAroundClassBody, :config do
  subject(:cop) { described_class.new(config) }

  let(:extra_begin) { 'Extra empty line detected at class body beginning.' }
  let(:extra_end) { 'Extra empty line detected at class body end.' }
  let(:missing_begin) { 'Empty line missing at class body beginning.' }
  let(:missing_end) { 'Empty line missing at class body end.' }
  let(:missing_def) { 'Empty line missing before first def definition' }
  let(:missing_type) { 'Empty line missing before first class definition' }

  context 'when EnforcedStyle is no_empty_lines' do
    let(:cop_config) { { 'EnforcedStyle' => 'no_empty_lines' } }

    it 'registers an offense for class body starting with a blank' do
      inspect_source(<<-RUBY.strip_indent)
        class SomeClass

          do_something
        end
      RUBY
      expect(cop.messages)
        .to eq([extra_begin])
    end

    it 'autocorrects class body containing only a blank' do
      corrected = autocorrect_source(<<-RUBY.strip_indent)
        class SomeClass

        end
      RUBY
      expect(corrected).to eq <<-RUBY.strip_indent
        class SomeClass
        end
      RUBY
    end

    it 'registers an offense for class body ending with a blank' do
      inspect_source(<<-RUBY.strip_indent)
        class SomeClass
          do_something

        end
      RUBY
      expect(cop.messages)
        .to eq([extra_end])
    end

    it 'registers an offense for singleton class body starting with a blank' do
      inspect_source(<<-RUBY.strip_indent)
        class << self

          do_something
        end
      RUBY
      expect(cop.messages)
        .to eq([extra_begin])
    end

    it 'autocorrects singleton class body containing only a blank' do
      corrected = autocorrect_source(<<-RUBY.strip_indent)
        class << self

        end
      RUBY
      expect(corrected).to eq <<-RUBY.strip_indent
        class << self
        end
      RUBY
    end

    it 'registers an offense for singleton class body ending with a blank' do
      inspect_source(<<-RUBY.strip_indent)
        class << self
          do_something

        end
      RUBY
      expect(cop.messages)
        .to eq([extra_end])
    end
  end

  context 'when EnforcedStyle is empty_lines' do
    let(:cop_config) { { 'EnforcedStyle' => 'empty_lines' } }

    it 'does not register offenses' do
      expect_no_offenses(<<-RUBY.strip_indent)
        class Foo

          def do_something
          end

        end
      RUBY
    end

    it 'does not register offenses when specifying a superclass ' \
       'that breaks the line' do
      expect_no_offenses(<<-RUBY.strip_indent)
        class Foo <
              Bar

          def do_something
          end

        end
      RUBY
    end

    it 'registers an offense for class body not starting or ending with a ' \
       'blank' do
      inspect_source(<<-RUBY.strip_indent)
        class SomeClass
          do_something
        end
      RUBY
      expect(cop.messages).to eq([missing_begin, missing_end])
    end

    it 'ignores classes with an empty body' do
      source = "class SomeClass\nend"
      corrected = autocorrect_source(source)
      expect(corrected).to eq(source)
    end

    it 'autocorrects beginning and end' do
      new_source = autocorrect_source(<<-RUBY.strip_indent)
        class SomeClass
          do_something
        end
      RUBY
      expect(new_source).to eq(<<-RUBY.strip_indent)
        class SomeClass

          do_something

        end
      RUBY
    end

    it 'registers an offense for singleton class body not starting or ending ' \
       'with a blank' do
      inspect_source(<<-RUBY.strip_indent)
        class << self
          do_something
        end
      RUBY
      expect(cop.messages).to eq([missing_begin, missing_end])
    end

    it 'ignores singleton classes with an empty body' do
      source = "class << self\nend"
      corrected = autocorrect_source(source)
      expect(corrected).to eq(source)
    end

    it 'autocorrects beginning and end for `class << self`' do
      new_source = autocorrect_source(<<-RUBY.strip_indent)
        class << self
          do_something
        end
      RUBY
      expect(new_source).to eq(<<-RUBY.strip_indent)
        class << self

          do_something

        end
      RUBY
    end
  end

  context 'when EnforcedStyle is empty_lines_except_namespace' do
    let(:cop_config) { { 'EnforcedStyle' => 'empty_lines_except_namespace' } }

    context 'when only child is class' do
      it 'requires no empty lines for namespace' do
        expect_no_offenses(<<-RUBY.strip_indent)
          class Parent < Base
            class Child

              do_something

            end
          end
        RUBY
      end

      it 'registers offense for namespace body starting with a blank' do
        inspect_source(<<-RUBY.strip_indent)
          class Parent

            class Child

              do_something

            end
          end
        RUBY
        expect(cop.messages).to eq([extra_begin])
      end

      it 'registers offense for namespace body ending with a blank' do
        inspect_source(<<-RUBY.strip_indent)
          class Parent
            class Child

              do_something

            end

          end
        RUBY
        expect(cop.messages).to eq([extra_end])
      end

      it 'registers offenses for namespaced class body not starting '\
          'with a blank' do
        inspect_source(<<-RUBY.strip_indent)
          class Parent
            class Child
              do_something

            end
          end
        RUBY
        expect(cop.messages).to eq([missing_begin])
      end

      it 'registers offenses for namespaced class body not ending '\
          'with a blank' do
        inspect_source(<<-RUBY.strip_indent)
          class Parent
            class Child

              do_something
            end
          end
        RUBY
        expect(cop.messages).to eq([missing_end])
      end

      it 'autocorrects beginning and end' do
        new_source = autocorrect_source(<<-RUBY.strip_indent)
          class Parent < Base

            class Child
              do_something
            end

          end
        RUBY
        expect(new_source).to eq(<<-RUBY.strip_indent)
          class Parent < Base
            class Child

              do_something

            end
          end
        RUBY
      end
    end

    context 'when only child is module' do
      it 'requires no empty lines for namespace' do
        expect_no_offenses(<<-RUBY.strip_indent)
          class Parent
            module Child
              do_something
            end
          end
        RUBY
      end

      it 'registers offense for namespace body starting with a blank' do
        inspect_source(<<-RUBY.strip_indent)
          class Parent

            module Child
              do_something
            end
          end
        RUBY
        expect(cop.messages).to eq([extra_begin])
      end

      it 'registers offense for namespace body ending with a blank' do
        inspect_source(<<-RUBY.strip_indent)
          class Parent
            module Child
              do_something
            end

          end
        RUBY
        expect(cop.messages).to eq([extra_end])
      end
    end

    context 'when has multiple child classes' do
      it 'requires empty lines for namespace' do
        expect_no_offenses(<<-RUBY.strip_indent)
          class Parent

            class Mom

              do_something

            end
            class Dad

            end

          end
        RUBY
      end

      it 'registers offenses for namespace body starting '\
        'and ending without a blank' do
        inspect_source(<<-RUBY.strip_indent)
          class Parent
            class Mom

              do_something

            end
            class Dad

            end
          end
        RUBY
        expect(cop.messages).to eq([missing_begin, missing_end])
      end
    end
  end

  context 'when EnforcedStyle is beginning_only' do
    let(:cop_config) { { 'EnforcedStyle' => 'beginning_only' } }

    it 'ignores empty lines at the beginning of a class' do
      expect_no_offenses(<<-RUBY.strip_indent)
        class SomeClass

          do_something
        end
      RUBY
    end

    it 'registers an offense for an empty line at the end of a class' do
      inspect_source(<<-RUBY.strip_indent)
        class SomeClass

          do_something

        end
      RUBY

      expect(cop.messages).to eq([extra_end])
    end

    it 'autocorrects end' do
      new_source = autocorrect_source(<<-RUBY.strip_indent)
        class SomeClass

          do_something

        end
      RUBY

      expect(new_source).to eq(<<-RUBY.strip_indent)
        class SomeClass

          do_something
        end
      RUBY
    end
  end

  context 'when EnforcedStyle is ending_only' do
    let(:cop_config) { { 'EnforcedStyle' => 'ending_only' } }

    it 'ignores empty lines at the beginning of a class' do
      expect_no_offenses(<<-RUBY.strip_indent)
        class SomeClass
          do_something

        end
      RUBY
    end

    it 'registers an offense for an empty line at the end of a class' do
      inspect_source(<<-RUBY.strip_indent)
        class SomeClass

          do_something

        end
      RUBY

      expect(cop.messages).to eq([extra_begin])
    end

    it 'autocorrects end' do
      new_source = autocorrect_source(<<-RUBY.strip_indent)
        class SomeClass

          do_something

        end
      RUBY

      expect(new_source).to eq(<<-RUBY.strip_indent)
        class SomeClass
          do_something

        end
      RUBY
    end
  end

  include_examples 'empty_lines_around_class_or_module_body', 'class'
end
