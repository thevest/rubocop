# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::FormatStringToken, :config do
  subject(:cop) { described_class.new(config) }

  let(:enforced_style) { :annotated }

  let(:cop_config) do
    {
      'EnforcedStyle' => enforced_style,
      'SupportedStyles' => %i[annotated template unannotated]
    }
  end

  shared_examples 'format string token style' do |name, good, bad|
    bad_style1 = bad

    context "when enforced style is #{name}" do
      let(:enforced_style) { name }

      it "registers offenses for #{bad_style1}" do
        inspect_source(<<-RUBY.strip_indent)
          <<-HEREDOC
          foo #{good} + bar #{bad_style1}
          HEREDOC
        RUBY

        expect(cop.highlights).to eql([bad_style1])
      end

      it 'supports dynamic string with interpolation' do
        inspect_source(
          %("a\#{b}#{good} c\#{d}#{bad_style1} e\#{f}")
        )

        expect(cop.highlights).to eql([bad_style1])
      end

      it 'sets the enforced style to annotated after inspecting "%<a>s"' do
        inspect_source('"%<a>s"')

        expect(cop.config_to_allow_offenses).to eq(
          'EnforcedStyle' => 'annotated'
        )
      end

      it 'configures the enforced style to template after inspecting "%{a}"' do
        inspect_source('"%{a}"')

        expect(cop.config_to_allow_offenses).to eq(
          'EnforcedStyle' => 'template'
        )
      end
    end
  end

  shared_examples 'enforced styles for format string tokens' do |token|
    template  = '%{template}'
    annotated = "%<named>#{token}"

    include_examples 'format string token style',
                     :annotated,
                     annotated,
                     template

    include_examples 'format string token style',
                     :template,
                     template,
                     annotated
  end

  shared_examples 'offense message' do |enforced_style, source, message|
    context "when enforced style is #{enforced_style}" do
      let(:enforced_style) { enforced_style }

      it 'gives a helpful error message' do
        inspect_source(source)

        expect(cop.messages.first).to eql(message)
      end
    end
  end

  it 'ignores xstr' do
    expect_no_offenses('`echo "%s %<annotated>s %{template}"`')
  end

  it 'ignores regexp' do
    expect_no_offenses('/foo bar %u/')
  end

  it 'ignores `%r` regexp' do
    expect_no_offenses('%r{foo bar %u}')
  end

  %i[strptime strftime].each do |method_name|
    it "ignores time format (when used as argument to #{method_name})" do
      expect_no_offenses(<<-RUBY.strip_indent)
        Time.#{method_name}('2017-12-13', '%Y-%m-%d')
      RUBY
    end
  end

  it 'ignores time format when it is stored in a variable' do
    expect_no_offenses(<<-RUBY.strip_indent)
      time_format = '%Y-%m-%d'
      Time.strftime('2017-12-13', time_format)
    RUBY
  end

  it 'ignores time format and unrelated `format` method using' do
    expect_no_offenses(<<-RUBY.strip_indent)
      Time.now.strftime('%Y-%m-%d-%H-%M-%S')
      format
    RUBY
  end

  it 'handles dstrs' do
    inspect_source('"c#{b}%{template}"')
    expect(cop.highlights).to eql(['%{template}'])
  end

  it 'ignores http links' do
    expect_no_offenses(<<-RUBY.strip_indent)
      'https://ru.wikipedia.org/wiki/%D0%90_'\
        '(%D0%BA%D0%B8%D1%80%D0%B8%D0%BB%D0%BB%D0%B8%D1%86%D0%B0)'
    RUBY
  end

  it 'ignores placeholder argumetns' do
    expect_no_offenses(<<-RUBY.strip_indent)
      format(
        '%<day>s %<start>s-%<end>s',
        day: open_house.starts_at.strftime('%a'),
        start: open_house.starts_at.strftime('%l'),
        end: open_house.ends_at.strftime('%l %p').strip
      )
    RUBY
  end

  it 'handles __FILE__' do
    expect_no_offenses('__FILE__')
  end

  it_behaves_like 'enforced styles for format string tokens', 'A'
  it_behaves_like 'enforced styles for format string tokens', 'B'
  it_behaves_like 'enforced styles for format string tokens', 'E'
  it_behaves_like 'enforced styles for format string tokens', 'G'
  it_behaves_like 'enforced styles for format string tokens', 'X'
  it_behaves_like 'enforced styles for format string tokens', 'a'
  it_behaves_like 'enforced styles for format string tokens', 'b'
  it_behaves_like 'enforced styles for format string tokens', 'c'
  it_behaves_like 'enforced styles for format string tokens', 'd'
  it_behaves_like 'enforced styles for format string tokens', 'e'
  it_behaves_like 'enforced styles for format string tokens', 'f'
  it_behaves_like 'enforced styles for format string tokens', 'g'
  it_behaves_like 'enforced styles for format string tokens', 'i'
  it_behaves_like 'enforced styles for format string tokens', 'o'
  it_behaves_like 'enforced styles for format string tokens', 'p'
  it_behaves_like 'enforced styles for format string tokens', 's'
  it_behaves_like 'enforced styles for format string tokens', 'u'
  it_behaves_like 'enforced styles for format string tokens', 'x'

  include_examples(
    'offense message',
    :annotated,
    '"%{foo}"',
    'Prefer annotated tokens (like `%<foo>s`) ' \
    'over template tokens (like `%{foo}`).'
  )

  include_examples(
    'offense message',
    :template,
    '"%<foo>d"',
    'Prefer template tokens (like `%{foo}`) ' \
    'over annotated tokens (like `%<foo>s`).'
  )

  include_examples(
    'offense message',
    :unannotated,
    '"%{foo}"',
    'Prefer unannotated tokens (like `%s`) ' \
    'over template tokens (like `%{foo}`).'
  )
end
