# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::InverseMethods do
  subject(:cop) { described_class.new(config) }

  let(:config) do
    RuboCop::Config.new(
      'Style/InverseMethods' => {
        'InverseMethods' => {
          any?: :none?,
          even?: :odd?,
          present?: :blank?,
          include?: :exclude?,
          :== => :!=,
          :=~ => :!~,
          :< => :>=,
          :> => :<=
        },
        'InverseBlocks' => {
          select: :reject,
          select!: :reject!
        }
      }
    )
  end

  it 'registers an offense for calling !.none? with a symbol proc' do
    expect_offense(<<-RUBY.strip_indent)
      !foo.none?(&:even?)
      ^^^^^^^^^^^^^^^^^^^ Use `any?` instead of inverting `none?`.
    RUBY
  end

  it 'registers an offense for calling !.none? with a block' do
    expect_offense(<<-RUBY.strip_indent)
      !foo.none? { |f| f.even? }
      ^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `any?` instead of inverting `none?`.
    RUBY
  end

  it 'allows a method call without a not' do
    expect_no_offenses('foo.none?')
  end

  it 'allows an inverse method when double negation is used' do
    expect_no_offenses('!!(string =~ /^\w+$/)')
  end

  it 'allows an inverse method with a block when double negation is used' do
    expect_no_offenses('!!foo.reject { |e| !e }')
  end

  context 'auto-correct' do
    it 'corrects !.none? with a symbol proc to any?' do
      new_source = autocorrect_source('!foo.none?(&:even?)')

      expect(new_source).to eq('foo.any?(&:even?)')
    end

    it 'corrects !.none? with a block to any?' do
      new_source = autocorrect_source('!foo.none? { |f| f.even? }')

      expect(new_source).to eq('foo.any? { |f| f.even? }')
    end
  end

  shared_examples 'all variable types' do |variable|
    it "registers an offense for calling !#{variable}.none?" do
      inspect_source("!#{variable}.none?")

      expect(cop.messages).to eq(['Use `any?` instead of inverting `none?`.'])
      expect(cop.highlights).to eq(["!#{variable}.none?"])
    end

    it "registers an offense for calling not #{variable}.none?" do
      inspect_source("not #{variable}.none?")

      expect(cop.messages).to eq(['Use `any?` instead of inverting `none?`.'])
      expect(cop.highlights).to eq(["not #{variable}.none?"])
    end

    it "corrects !#{variable}.none? to #{variable}.any?" do
      new_source = autocorrect_source("!#{variable}.none?")

      expect(new_source).to eq("#{variable}.any?")
    end

    it "corrects not #{variable}.none? to #{variable}.any?" do
      new_source = autocorrect_source("not #{variable}.none?")

      expect(new_source).to eq("#{variable}.any?")
    end
  end

  it_behaves_like 'all variable types', 'foo'
  it_behaves_like 'all variable types', '$foo'
  it_behaves_like 'all variable types', '@foo'
  it_behaves_like 'all variable types', '@@foo'
  it_behaves_like 'all variable types', 'FOO'
  it_behaves_like 'all variable types', 'FOO::BAR'
  it_behaves_like 'all variable types', 'foo["bar"]'
  it_behaves_like 'all variable types', 'foo.bar'

  { any?: :none?,
    even?: :odd?,
    present?: :blank?,
    include?: :exclude?,
    none?: :any?,
    odd?: :even?,
    blank?: :present?,
    exclude?: :include? }.each do |method, inverse|
      it "registers an offense for !foo.#{method}" do
        inspect_source("!foo.#{method}")

        expect(cop.messages)
          .to eq(["Use `#{inverse}` instead of inverting `#{method}`."])
      end

      it "corrects #{method} to #{inverse}" do
        new_source = autocorrect_source("!foo.#{method}")

        expect(new_source).to eq("foo.#{inverse}")
      end
    end

  { :== => :!=,
    :!= => :==,
    :=~ => :!~,
    :!~ => :=~,
    :< => :>=,
    :> => :<= }.each do |method, inverse|
    it "registers an offense for !(foo #{method} bar)" do
      inspect_source("!(foo #{method} bar)")

      expect(cop.messages)
        .to eq(["Use `#{inverse}` instead of inverting `#{method}`."])
    end

    it "registers an offense for not (foo #{method} bar)" do
      inspect_source("not (foo #{method} bar)")

      expect(cop.messages)
        .to eq(["Use `#{inverse}` instead of inverting `#{method}`."])
    end

    it "corrects #{method} to #{inverse}" do
      new_source = autocorrect_source("!(foo #{method} bar)")

      expect(new_source).to eq("foo #{inverse} bar")
    end
  end

  it 'allows comparing camel case constants on the right' do
    expect_no_offenses(<<-RUBY.strip_indent)
      klass = self.class
      !(klass < BaseClass)
    RUBY
  end

  it 'allows comparing camel case constants on the left' do
    expect_no_offenses(<<-RUBY.strip_indent)
      klass = self.class
      !(BaseClass < klass)
    RUBY
  end

  it 'registers an offense for comparing snake case constants on the right' do
    expect_offense(<<-RUBY.strip_indent)
      klass = self.class
      !(klass < FOO_BAR)
      ^^^^^^^^^^^^^^^^^^ Use `>=` instead of inverting `<`.
    RUBY
  end

  it 'registers an offense for comparing snake case constants on the left' do
    expect_offense(<<-RUBY.strip_indent)
      klass = self.class
      !(FOO_BAR < klass)
      ^^^^^^^^^^^^^^^^^^ Use `>=` instead of inverting `<`.
    RUBY
  end

  context 'inverse blocks' do
    { select: :reject,
      reject: :select,
      select!: :reject!,
      reject!: :select! }.each do |method, inverse|
      it "registers an offense for foo.#{method} { |e| !e }" do
        inspect_source("foo.#{method} { |e| !e }")

        expect(cop.messages)
          .to eq(["Use `#{inverse}` instead of inverting `#{method}`."])
      end

      it 'registers an offense for a multiline method call where the last ' \
        'method is inverted' do
        inspect_source(<<-RUBY.strip_indent)
          foo.#{method} do |e|
            something
            !e.bar
          end
        RUBY

        expect(cop.messages)
          .to eq(["Use `#{inverse}` instead of inverting `#{method}`."])
      end

      it 'registers an offense for an inverted equality block' do
        expect_offense(<<-RUBY.strip_indent)
          foo.select { |e| e != 2 }
          ^^^^^^^^^^^^^^^^^^^^^^^^^ Use `reject` instead of inverting `select`.
        RUBY
      end

      it 'registers an offense for a multiline inverted equality block' do
        inspect_source(<<-RUBY.strip_indent)
          foo.#{method} do |e|
            something
            something_else
            e != 2
          end
        RUBY

        expect(cop.messages)
          .to eq(["Use `#{inverse}` instead of inverting `#{method}`."])
      end

      it 'registers a single offense for nested inverse method calls' do
        inspect_source(<<-RUBY.strip_indent)
          y.#{method} { |key, _value| !(key =~ /c\d/) }
        RUBY

        expect(cop.messages)
          .to eq(["Use `#{inverse}` instead of inverting `#{method}`."])
      end

      it 'corrects nested inverse method calls' do
        new_source =
          autocorrect_source("y.#{method} { |key, _value| !(key =~ /c\d/) }")

        expect(new_source)
          .to eq("y.#{inverse} { |key, _value| (key =~ /c\d/) }")
      end

      it 'corrects a simple inverted block' do
        new_source = autocorrect_source("foo.#{method} { |e| !e }")

        expect(new_source).to eq("foo.#{inverse} { |e| e }")
      end

      it 'corrects an inverted method call' do
        new_source = autocorrect_source("foo.#{method} { |e| !e.bar? }")

        expect(new_source).to eq("foo.#{inverse} { |e| e.bar? }")
      end

      it 'corrects a complex inverted method call' do
        source = "puts 1 if !foo.#{method} { |e| !e.bar? }"
        new_source = autocorrect_source(source)

        expect(new_source).to eq("puts 1 if !foo.#{inverse} { |e| e.bar? }")
      end

      it 'corrects an inverted do end method call' do
        new_source = autocorrect_source(<<-RUBY.strip_indent)
          foo.#{method} do |e|
            !e.bar
          end
        RUBY

        expect(new_source).to eq(<<-RUBY.strip_indent)
          foo.#{inverse} do |e|
            e.bar
          end
        RUBY
      end

      it 'corrects a multiline method call where the last method is inverted' do
        new_source = autocorrect_source(<<-RUBY.strip_indent)
          foo.#{method} do |e|
            something
            something_else
            !e.bar
          end
        RUBY

        expect(new_source).to eq(<<-RUBY.strip_indent)
          foo.#{inverse} do |e|
            something
            something_else
            e.bar
          end
        RUBY
      end

      it 'corrects an offense for an inverted equality block' do
        new_source = autocorrect_source("foo.#{method} { |e| e != 2 }")

        expect(new_source).to eq("foo.#{inverse} { |e| e == 2 }")
      end

      it 'corrects an offense for a multiline inverted equality block' do
        new_source = autocorrect_source(<<-RUBY.strip_indent)
          foo.#{method} do |e|
            something
            something_else
            e != 2
          end
        RUBY

        expect(new_source).to eq(<<-RUBY.strip_indent)
          foo.#{inverse} do |e|
            something
            something_else
            e == 2
          end
        RUBY
      end
    end
  end
end
