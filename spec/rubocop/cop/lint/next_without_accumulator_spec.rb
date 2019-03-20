# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Lint::NextWithoutAccumulator do
  subject(:cop) { described_class.new }

  def code_without_accumulator(method_name)
    <<-RUBY
      (1..4).#{method_name}(0) do |acc, i|
        next if i.odd?
        acc + i
      end
    RUBY
  end

  def code_with_accumulator(method_name)
    <<-RUBY
      (1..4).#{method_name}(0) do |acc, i|
        next acc if i.odd?
        acc + i
      end
    RUBY
  end

  def code_with_nested_block(method_name)
    <<-RUBY
      [(1..3), (4..6)].#{method_name}(0) do |acc, elems|
        elems.each_with_index do |elem, i|
          next if i == 1
          acc << elem
        end
        acc
      end
    RUBY
  end

  shared_examples 'reduce/inject' do |reduce_alias|
    context "given a #{reduce_alias} block" do
      it 'registers an offense for a bare next' do
        inspect_source(code_without_accumulator(reduce_alias))
        expect(cop.offenses.size).to eq(1)
        expect(cop.highlights).to eq(['next'])
      end

      it 'accepts next with a value' do
        expect_no_offenses(code_with_accumulator(reduce_alias))
      end

      it 'accepts next within a nested block' do
        expect_no_offenses(code_with_nested_block(reduce_alias))
      end
    end
  end

  it_behaves_like 'reduce/inject', :reduce
  it_behaves_like 'reduce/inject', :inject

  context 'given an unrelated block' do
    it 'accepts a bare next' do
      expect_no_offenses(<<-RUBY.strip_indent)
              (1..4).foo(0) do |acc, i|
                next if i.odd?
                acc + i
              end
      RUBY
    end

    it 'accepts next with a value' do
      expect_no_offenses(<<-RUBY.strip_indent)
              (1..4).foo(0) do |acc, i|
                next acc if i.odd?
                acc + i
              end
      RUBY
    end
  end
end
