# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Lint::RedundantWithObject do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  it 'registers an offense when using `ary.each_with_object { |v| v }`' do
    expect_offense(<<-RUBY.strip_indent)
      ary.each_with_object([]) { |v| v }
          ^^^^^^^^^^^^^^^^^^^^ Use `each` instead of `each_with_object`.
    RUBY
  end

  it 'registers an offense when using `ary.each.with_object([]) { |v| v }`' do
    expect_offense(<<-RUBY.strip_indent)
      ary.each.with_object([]) { |v| v }
               ^^^^^^^^^^^^^^^ Remove redundant `with_object`.
    RUBY
  end

  it 'autocorrects to ary.each from ary.each_with_object([])' do
    new_source = autocorrect_source('ary.each_with_object([]) { |v| v }')

    expect(new_source).to eq 'ary.each { |v| v }'
  end

  it 'autocorrects to ary.each from ary.each_with_object []' do
    new_source = autocorrect_source('ary.each_with_object [] { |v| v }')

    expect(new_source).to eq 'ary.each { |v| v }'
  end

  it 'autocorrects to ary.each from ary.each_with_object([]) do-end block' do
    new_source = autocorrect_source(<<-RUBY.strip_indent)
      ary.each_with_object([]) do |v|
        v
      end
    RUBY

    expect(new_source).to eq(<<-RUBY.strip_indent)
      ary.each do |v|
        v
      end
    RUBY
  end

  it 'autocorrects to ary.each from ary.each_with_object do-end block' do
    new_source = autocorrect_source(<<-RUBY.strip_indent)
      ary.each_with_object [] do |v|
        v
      end
    RUBY

    expect(new_source).to eq(<<-RUBY.strip_indent)
      ary.each do |v|
        v
      end
    RUBY
  end

  it 'autocorrects to ary.each from ary.each.with_object([]) { |v| v }' do
    new_source = autocorrect_source('ary.each.with_object([]) { |v| v }')

    expect(new_source).to eq 'ary.each { |v| v }'
  end

  it 'autocorrects to ary.each from ary.each.with_object [] { |v| v }' do
    new_source = autocorrect_source('ary.each.with_object [] { |v| v }')

    expect(new_source).to eq 'ary.each { |v| v }'
  end

  it 'an object is used as a block argument' do
    expect_no_offenses('ary.each_with_object([]) { |v, o| v; o }')
  end

  context 'when missing argument to `each_with_object`' do
    it 'does not register an offense when block has 2 arguments' do
      expect_no_offenses('ary.each_with_object { |v, o| v; o }')
    end

    it 'does not register an offense when block has 1 argument' do
      expect_no_offenses('ary.each_with_object { |v| v }')
    end
  end
end
