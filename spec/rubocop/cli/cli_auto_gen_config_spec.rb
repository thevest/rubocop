# frozen_string_literal: true

require 'timeout'

RSpec.describe RuboCop::CLI, :isolated_environment do
  include_context 'cli spec behavior'

  subject(:cli) { described_class.new }

  describe '--auto-gen-config' do
    before do
      RuboCop::Formatter::DisabledConfigFormatter
        .config_to_allow_offenses = {}
    end

    shared_examples 'LineLength handling' do |ctx, initial_dotfile, exp_dotfile|
      context ctx do
        # Since there is a line with length 99 in the inspected code,
        # Style/IfUnlessModifier will register an offense when
        # Metrics/LineLength:Max has been set to 99. With a lower
        # LineLength:Max there would be no IfUnlessModifier offense.
        it "bases other cops' configuration on the code base's current " \
           'maximum line length' do
          if initial_dotfile
            initial_config = YAML.safe_load(initial_dotfile.join($RS)) || {}
            inherited_files = Array(initial_config['inherit_from'])
            (inherited_files - ['.rubocop.yml']).each do |f|
              create_empty_file(f)
            end

            create_file('.rubocop.yml', initial_dotfile)
            create_file('.rubocop_todo.yml', [''])
          end
          create_file('example.rb', <<-RUBY.strip_indent)
            def f
            #{'  #' * 33}
              if #{'a' * 80}
                return y
              end

              z
            end
          RUBY
          expect(cli.run(['--auto-gen-config'])).to eq(0)
          expect(IO.readlines('.rubocop_todo.yml')
                   .drop_while { |line| line.start_with?('#') }.join)
            .to eq(<<-YAML.strip_indent)

              # Offense count: 1
              # Cop supports --auto-correct.
              Style/IfUnlessModifier:
                Exclude:
                  - 'example.rb'

              # Offense count: 2
              # Configuration parameters: AllowHeredoc, AllowURI, URISchemes, IgnoreCopDirectives, IgnoredPatterns.
              # URISchemes: http, https
              Metrics/LineLength:
                Max: 99
          YAML
          expect(IO.read('.rubocop.yml').strip).to eq(exp_dotfile.join($RS))
          $stdout = StringIO.new
          expect(described_class.new.run([])).to eq(0)
          expect($stderr.string).to eq('')
          expect($stdout.string).to include('no offenses detected')
        end
      end
    end

    include_examples 'LineLength handling',
                     'when .rubocop.yml does not exist',
                     nil,
                     ['inherit_from: .rubocop_todo.yml']

    include_examples 'LineLength handling',
                     'when .rubocop.yml is empty',
                     [''],
                     ['inherit_from: .rubocop_todo.yml']

    include_examples 'LineLength handling',
                     'when .rubocop.yml inherits only from .rubocop_todo.yml',
                     ['inherit_from: .rubocop_todo.yml'],
                     ['inherit_from: .rubocop_todo.yml']

    include_examples 'LineLength handling',
                     'when .rubocop.yml inherits only from .rubocop_todo.yml ' \
                     'in an array',
                     ['inherit_from:',
                      '  - .rubocop_todo.yml'],
                     ['inherit_from:',
                      '  - .rubocop_todo.yml']

    include_examples 'LineLength handling',
                     'when .rubocop.yml inherits from another file and ' \
                     '.rubocop_todo.yml',
                     ['inherit_from:',
                      '  - common.yml',
                      '  - .rubocop_todo.yml'],
                     ['inherit_from:',
                      '  - common.yml',
                      '  - .rubocop_todo.yml']

    include_examples 'LineLength handling',
                     'when .rubocop.yml inherits from two other files',
                     ['inherit_from:',
                      '  - common1.yml',
                      '  - common2.yml'],
                     ['inherit_from:',
                      '  - .rubocop_todo.yml',
                      '  - common1.yml',
                      '  - common2.yml']

    include_examples 'LineLength handling',
                     'when .rubocop.yml inherits from another file',
                     ['inherit_from: common.yml'],
                     ['inherit_from:',
                      '  - .rubocop_todo.yml',
                      '  - common.yml']

    include_examples 'LineLength handling',
                     "when .rubocop.yml doesn't inherit",
                     ['Style/For:',
                      '  Enabled: false'],
                     ['inherit_from: .rubocop_todo.yml',
                      '',
                      'Style/For:',
                      '  Enabled: false']

    context 'with Metrics/LineLength:Max overridden' do
      before do
        create_file('.rubocop.yml', ['Metrics/LineLength:',
                                     "  Max: #{line_length_max}",
                                     "  Enabled: #{line_length_enabled}"])
        create_file('.rubocop_todo.yml', [''])
        create_file('example.rb', <<-RUBY.strip_indent)
          def f
          #{'  #' * 33}
            if #{'a' * 80}
              return y
            end

            z
          end
        RUBY
      end

      context 'when .rubocop.yml has Metrics/LineLength:Max less than code ' \
              'base max' do
        let(:line_length_max) { 90 }
        let(:line_length_enabled) { true }

        it "bases other cops' configuration on the overridden LineLength:Max" do
          expect(cli.run(['--auto-gen-config'])).to eq(0)
          expect($stdout.string).to include(<<-YAML.strip_indent)
            Added inheritance from `.rubocop_todo.yml` in `.rubocop.yml`.
            Phase 1 of 2: run Metrics/LineLength cop (skipped because the default Metrics/LineLength:Max is overridden)
            Phase 2 of 2: run all cops
          YAML
          # We generate a Metrics/LineLength:Max even though it's overridden in
          # .rubocop.yml. We want to show somewhere what the actual maximum is.
          #
          # Note that there is no Style/IfUnlessModifier offense registered due
          # to the Max:90 setting.
          expect(IO.readlines('.rubocop_todo.yml')
                  .drop_while { |line| line.start_with?('#') }.join)
            .to eq(<<-YAML.strip_indent)

              # Offense count: 1
              # Configuration parameters: AllowHeredoc, AllowURI, URISchemes, IgnoreCopDirectives, IgnoredPatterns.
              # URISchemes: http, https
              Metrics/LineLength:
                Max: 99
            YAML
          expect(IO.read('.rubocop.yml')).to eq(<<-YAML.strip_indent)
            inherit_from: .rubocop_todo.yml

            Metrics/LineLength:
              Max: 90
              Enabled: true
          YAML
          $stdout = StringIO.new
          expect(described_class.new.run(%w[--format simple --debug])).to eq(1)
          expect($stdout.string)
            .to include('.rubocop.yml: Metrics/LineLength:Max overrides the ' \
                        "same parameter in .rubocop_todo.yml\n")
          expect($stdout.string).to include(<<-OUTPUT.strip_indent)
            == example.rb ==
            C:  2: 91: Metrics/LineLength: Line is too long. [99/90]

            1 file inspected, 1 offense detected
          OUTPUT
        end
      end

      context 'when .rubocop.yml has Metrics/LineLength disabled ' do
        let(:line_length_max) { 90 }
        let(:line_length_enabled) { false }

        it 'skips the cop from both phases of the run' do
          expect(cli.run(['--auto-gen-config'])).to eq(0)
          expect($stdout.string).to include(<<-YAML.strip_indent)
            Added inheritance from `.rubocop_todo.yml` in `.rubocop.yml`.
            Phase 1 of 2: run Metrics/LineLength cop (skipped because Metrics/LineLength is disabled)
            Phase 2 of 2: run all cops
          YAML

          # The code base max line length is 99, but the setting Enabled: false
          # overrides that so no Metrics/LineLength:Max setting is generated in
          # .rubocop_todo.yml.
          expect(IO.readlines('.rubocop_todo.yml')
                  .drop_while { |line| line.start_with?('#') }.join)
            .to eq(<<-YAML.strip_indent)

              # Offense count: 1
              # Cop supports --auto-correct.
              Style/IfUnlessModifier:
                Exclude:
                  - 'example.rb'
            YAML
          expect(IO.read('.rubocop.yml')).to eq(<<-YAML.strip_indent)
            inherit_from: .rubocop_todo.yml

            Metrics/LineLength:
              Max: 90
              Enabled: false
          YAML
          $stdout = StringIO.new
          expect(described_class.new.run(%w[--format simple])).to eq(0)
          expect($stderr.string).to eq('')
          expect($stdout.string).to eq(<<-OUTPUT.strip_indent)

            1 file inspected, no offenses detected
          OUTPUT
        end
      end

      context 'when .rubocop.yml has Metrics/LineLength:Max more than code ' \
              'base max' do
        let(:line_length_max) { 150 }
        let(:line_length_enabled) { true }

        it "bases other cops' configuration on the overridden LineLength:Max" do
          expect(cli.run(['--auto-gen-config'])).to eq(0)
          expect($stdout.string).to include(<<-YAML.strip_indent)
            Added inheritance from `.rubocop_todo.yml` in `.rubocop.yml`.
            Phase 1 of 2: run Metrics/LineLength cop (skipped because the default Metrics/LineLength:Max is overridden)
            Phase 2 of 2: run all cops
          YAML
          # The code base max line length is 99, but the setting Max:150
          # overrides that so no Metrics/LineLength:Max setting is generated in
          # .rubocop_todo.yml.
          expect(IO.readlines('.rubocop_todo.yml')
                  .drop_while { |line| line.start_with?('#') }.join)
            .to eq(<<-YAML.strip_indent)

              # Offense count: 1
              # Cop supports --auto-correct.
              Style/IfUnlessModifier:
                Exclude:
                  - 'example.rb'
            YAML
          expect(IO.read('.rubocop.yml')).to eq(<<-YAML.strip_indent)
            inherit_from: .rubocop_todo.yml

            Metrics/LineLength:
              Max: 150
              Enabled: true
          YAML
          $stdout = StringIO.new
          expect(described_class.new.run(%w[--format simple])).to eq(0)
          expect($stderr.string).to eq('')
          expect($stdout.string).to eq(<<-OUTPUT.strip_indent)

            1 file inspected, no offenses detected
          OUTPUT
        end
      end
    end

    it 'overwrites an existing todo file' do
      create_file('example1.rb', ['x= 0 ',
                                  '#' * 85,
                                  'y ',
                                  'puts x'])
      create_file('.rubocop_todo.yml', <<-YAML.strip_indent)
        Metrics/LineLength:
          Enabled: false
      YAML
      create_file('.rubocop.yml', ['inherit_from: .rubocop_todo.yml'])
      expect(cli.run(['--auto-gen-config'])).to eq(0)
      expect(IO.readlines('.rubocop_todo.yml')[8..-1].map(&:chomp))
        .to eq(['# Offense count: 1',
                '# Cop supports --auto-correct.',
                '# Configuration parameters: AllowForAlignment.',
                'Layout/SpaceAroundOperators:',
                '  Exclude:',
                "    - 'example1.rb'",
                '',
                '# Offense count: 2',
                '# Cop supports --auto-correct.',
                '# Configuration parameters: AllowInHeredoc.',
                'Layout/TrailingWhitespace:',
                '  Exclude:',
                "    - 'example1.rb'",
                '',
                '# Offense count: 1',
                '# Configuration parameters: AllowHeredoc, AllowURI, ' \
                'URISchemes, IgnoreCopDirectives, IgnoredPatterns.',
                '# URISchemes: http, https',
                'Metrics/LineLength:',
                '  Max: 85'])

      # Create new CLI instance to avoid using cached configuration.
      new_cli = described_class.new

      expect(new_cli.run(['example1.rb'])).to eq(0)
    end

    it 'honors rubocop:disable comments' do
      create_file('example1.rb', ['#' * 81,
                                  '# rubocop:disable LineLength',
                                  '#' * 85,
                                  'y ',
                                  'puts 123456',
                                  '# rubocop:enable LineLength'])
      create_file('.rubocop.yml', ['inherit_from: .rubocop_todo.yml'])
      create_file('.rubocop_todo.yml', [''])
      expect(cli.run(['--auto-gen-config'])).to eq(0)
      expect(IO.readlines('.rubocop_todo.yml')[8..-1].join)
        .to eq(['# Offense count: 1',
                '# Cop supports --auto-correct.',
                '# Configuration parameters: AllowInHeredoc.',
                'Layout/TrailingWhitespace:',
                '  Exclude:',
                "    - 'example1.rb'",
                '',
                '# Offense count: 1',
                '# Cop supports --auto-correct.',
                '# Configuration parameters: Strict.',
                'Style/NumericLiterals:',
                '  MinDigits: 7',
                '',
                '# Offense count: 1',
                '# Configuration parameters: AllowHeredoc, AllowURI, ' \
                'URISchemes, IgnoreCopDirectives, IgnoredPatterns.',
                '# URISchemes: http, https',
                'Metrics/LineLength:',
                '  Max: 81',
                ''].join("\n"))
    end

    context 'when --config is used' do
      it 'can generate a todo list' do
        create_file('example1.rb', ['$x = 0 ',
                                    '#' * 90,
                                    'y ',
                                    'puts x'])
        create_file('dir/cop_config.yml', <<-YAML.strip_indent)
          Layout/TrailingWhitespace:
            Enabled: false
          Metrics/LineLength:
            Max: 95
        YAML
        expect(cli.run(%w[--auto-gen-config --config dir/cop_config.yml]))
          .to eq(0)
        expect(Dir['.*']).to include('.rubocop_todo.yml')
        todo_contents = IO.read('.rubocop_todo.yml').lines[8..-1].join
        expect(todo_contents).to eq(<<-YAML.strip_indent)
          # Offense count: 1
          # Configuration parameters: AllowedVariables.
          Style/GlobalVars:
            Exclude:
              - 'example1.rb'
        YAML
        expect(IO.read('dir/cop_config.yml')).to eq(<<-YAML.strip_indent)
          inherit_from: .rubocop_todo.yml

          Layout/TrailingWhitespace:
            Enabled: false
          Metrics/LineLength:
            Max: 95
        YAML
      end
    end

    context 'when working in a subdirectory' do
      it 'can generate a todo list' do
        create_file('dir/example1.rb', ['$x = 0 ',
                                        '#' * 90,
                                        'y ',
                                        'puts x'])
        create_file('dir/.rubocop.yml', <<-YAML.strip_indent)
          inherit_from: ../.rubocop.yml
        YAML
        create_file('.rubocop.yml', <<-YAML.strip_indent)
          Layout/TrailingWhitespace:
            Enabled: false
          Metrics/LineLength:
            Max: 95
        YAML
        RuboCop::PathUtil.chdir('dir') do
          expect(cli.run(%w[--auto-gen-config])).to eq(0)
        end
        expect($stderr.string).to eq('')
        # expect($stdout.string).to include('Created .rubocop_todo.yml.')
        expect(Dir['dir/.*']).to include('dir/.rubocop_todo.yml')
        todo_contents = IO.read('dir/.rubocop_todo.yml').lines[8..-1].join
        expect(todo_contents).to eq(<<-YAML.strip_indent)
          # Offense count: 1
          # Configuration parameters: AllowedVariables.
          Style/GlobalVars:
            Exclude:
              - 'example1.rb'
        YAML
        expect(IO.read('dir/.rubocop.yml')).to eq(<<-YAML.strip_indent)
          inherit_from:
            - .rubocop_todo.yml
            - ../.rubocop.yml
        YAML
      end
    end

    it 'can generate a todo list' do
      create_file('example1.rb', ['$x= 0 ',
                                  '#' * 90,
                                  '#' * 85,
                                  'y ',
                                  'puts x'])
      create_file('example2.rb', <<-RUBY.strip_indent)
        # frozen_string_literal: true

        \tx = 0
        puts x

        class A
          def a; end
        end
      RUBY
      # Make ConfigLoader reload the default configuration so that its
      # absolute Exclude paths will point into this example's work directory.
      RuboCop::ConfigLoader.default_configuration = nil

      expect(cli.run(['--auto-gen-config'])).to eq(0)
      expect($stderr.string).to eq('')
      expect($stdout.string).to include('Created .rubocop_todo.yml.')
      expected =
        ['# This configuration was generated by',
         '# `rubocop --auto-gen-config`',
         /# on .* using RuboCop version .*/,
         '# The point is for the user to remove these configuration records',
         '# one by one as the offenses are removed from the code base.',
         '# Note that changes in the inspected code, or installation of new',
         '# versions of RuboCop, may require this file to be generated ' \
         'again.',
         '',
         '# Offense count: 1',
         '# Cop supports --auto-correct.',
         'Layout/CommentIndentation:',
         '  Exclude:',
         "    - 'example2.rb'",
         '',
         '# Offense count: 2',
         '# Cop supports --auto-correct.',
         '# Configuration parameters: EnforcedStyle.',
         '# SupportedStyles: normal, rails',
         'Layout/IndentationConsistency:',
         '  Exclude:',
         "    - 'example2.rb'",
         '',
         '# Offense count: 1',
         '# Cop supports --auto-correct.',
         'Layout/InitialIndentation:',
         '  Exclude:',
         "    - 'example2.rb'",
         '',
         '# Offense count: 1',
         '# Cop supports --auto-correct.',
         '# Configuration parameters: AllowForAlignment.',
         'Layout/SpaceAroundOperators:',
         '  Exclude:',
         "    - 'example1.rb'",
         '',
         '# Offense count: 1',
         '# Cop supports --auto-correct.',
         '# Configuration parameters: IndentationWidth.',
         'Layout/Tab:',
         '  Exclude:',
         "    - 'example2.rb'",
         '',
         '# Offense count: 2',
         '# Cop supports --auto-correct.',
         '# Configuration parameters: AllowInHeredoc.',
         'Layout/TrailingWhitespace:',
         '  Exclude:',
         "    - 'example1.rb'",
         '',
         '# Offense count: 1',
         'Style/Documentation:',
         '  Exclude:',
         "    - 'spec/**/*'", # Copied from default configuration
         "    - 'test/**/*'", # Copied from default configuration
         "    - 'example2.rb'",
         '',
         '# Offense count: 1',
         '# Configuration parameters: AllowedVariables.',
         'Style/GlobalVars:',
         '  Exclude:',
         "    - 'example1.rb'",
         '',
         '# Offense count: 2',
         '# Configuration parameters: AllowHeredoc, AllowURI, URISchemes, ' \
         'IgnoreCopDirectives, IgnoredPatterns.',
         '# URISchemes: http, https',
         'Metrics/LineLength:',
         '  Max: 90']
      actual = IO.read('.rubocop_todo.yml').split($RS)
      expected.each_with_index do |line, ix|
        if line.is_a?(String)
          expect(actual[ix]).to eq(line)
        else
          expect(actual[ix]).to match(line)
        end
      end
      expect(actual.size).to eq(expected.size)
    end

    it 'can generate Exclude properties with a given limit' do
      create_file('example1.rb', ['$x= 0 ',
                                  '#' * 90,
                                  '#' * 85,
                                  'y ',
                                  'puts x'])
      create_file('example2.rb', ['# frozen_string_literal: true',
                                  '',
                                  '#' * 85,
                                  "\tx = 0",
                                  'puts x '])
      expect(cli.run(['--auto-gen-config', '--exclude-limit', '1'])).to eq(0)
      expected =
        ['# This configuration was generated by',
         '# `rubocop --auto-gen-config --exclude-limit 1`',
         /# on .* using RuboCop version .*/,
         '# The point is for the user to remove these configuration records',
         '# one by one as the offenses are removed from the code base.',
         '# Note that changes in the inspected code, or installation of new',
         '# versions of RuboCop, may require this file to be generated ' \
         'again.',
         '',
         '# Offense count: 1',
         '# Cop supports --auto-correct.',
         'Layout/CommentIndentation:',
         '  Exclude:',
         "    - 'example2.rb'",
         '',
         '# Offense count: 1',
         '# Cop supports --auto-correct.',
         '# Configuration parameters: EnforcedStyle.',
         '# SupportedStyles: normal, rails',
         'Layout/IndentationConsistency:',
         '  Exclude:',
         "    - 'example2.rb'",
         '',
         '# Offense count: 1',
         '# Cop supports --auto-correct.',
         'Layout/InitialIndentation:',
         '  Exclude:',
         "    - 'example2.rb'",
         '',
         '# Offense count: 1',
         '# Cop supports --auto-correct.',
         '# Configuration parameters: AllowForAlignment.',
         'Layout/SpaceAroundOperators:',
         '  Exclude:',
         "    - 'example1.rb'",
         '',
         '# Offense count: 1',
         '# Cop supports --auto-correct.',
         '# Configuration parameters: IndentationWidth.',
         'Layout/Tab:',
         '  Exclude:',
         "    - 'example2.rb'",
         '',
         '# Offense count: 3',
         '# Cop supports --auto-correct.',
         '# Configuration parameters: AllowInHeredoc.',
         'Layout/TrailingWhitespace:',
         '  Enabled: false', # Offenses in 2 files, limit is 1, so no Exclude
         '',
         '# Offense count: 1',
         '# Configuration parameters: AllowedVariables.',
         'Style/GlobalVars:',
         '  Exclude:',
         "    - 'example1.rb'",
         '',
         '# Offense count: 3',
         '# Configuration parameters: AllowHeredoc, AllowURI, URISchemes, ' \
         'IgnoreCopDirectives, IgnoredPatterns.',
         '# URISchemes: http, https',
         'Metrics/LineLength:',
         '  Max: 90']
      actual = IO.read('.rubocop_todo.yml').split($RS)
      expected.each_with_index do |line, ix|
        if line.is_a?(String)
          expect(actual[ix]).to eq(line)
        else
          expect(actual[ix]).to match(line)
        end
      end
      expect(actual.size).to eq(expected.size)
    end

    it 'does not generate configuration for the Syntax cop' do
      create_file('example1.rb', <<-RUBY.strip_indent)
        # frozen_string_literal: true

        x = <  # Syntax error
        puts x
      RUBY
      create_file('example2.rb', <<-RUBY.strip_indent)
        # frozen_string_literal: true

        \tx = 0
        puts x
      RUBY
      expect(cli.run(['--auto-gen-config'])).to eq(0)
      expect($stderr.string).to eq('')
      expected =
        ['# This configuration was generated by',
         '# `rubocop --auto-gen-config`',
         /# on .* using RuboCop version .*/,
         '# The point is for the user to remove these configuration records',
         '# one by one as the offenses are removed from the code base.',
         '# Note that changes in the inspected code, or installation of new',
         '# versions of RuboCop, may require this file to be generated ' \
         'again.',
         '',
         '# Offense count: 1',
         '# Cop supports --auto-correct.',
         'Layout/CommentIndentation:',
         '  Exclude:',
         "    - 'example2.rb'",
         '',
         '# Offense count: 1',
         '# Cop supports --auto-correct.',
         '# Configuration parameters: EnforcedStyle.',
         '# SupportedStyles: normal, rails',
         'Layout/IndentationConsistency:',
         '  Exclude:',
         "    - 'example2.rb'",
         '',
         '# Offense count: 1',
         '# Cop supports --auto-correct.',
         'Layout/InitialIndentation:',
         '  Exclude:',
         "    - 'example2.rb'",
         '',
         '# Offense count: 1',
         '# Cop supports --auto-correct.',
         '# Configuration parameters: IndentationWidth.',
         'Layout/Tab:',
         '  Exclude:',
         "    - 'example2.rb'"]
      actual = IO.read('.rubocop_todo.yml').split($RS)
      expect(actual.length).to eq(expected.length)
      expected.each_with_index do |line, ix|
        if line.is_a?(String)
          expect(actual[ix]).to eq(line)
        else
          expect(actual[ix]).to match(line)
        end
      end
      expect(actual.size).to eq(expected.size)
    end

    it 'generates a todo list that removes the reports' do
      create_file('example.rb', 'y.gsub!(/abc\/xyz/, x)')
      expect(cli.run(%w[--format emacs])).to eq(1)
      expect($stdout.string).to eq(
        "#{abs('example.rb')}:1:9: C: Style/RegexpLiteral: Use `%r` " \
        "around regular expression.\n"
      )
      expect(cli.run(['--auto-gen-config'])).to eq(0)
      expected =
        ['# This configuration was generated by',
         '# `rubocop --auto-gen-config`',
         /# on .* using RuboCop version .*/,
         '# The point is for the user to remove these configuration records',
         '# one by one as the offenses are removed from the code base.',
         '# Note that changes in the inspected code, or installation of new',
         '# versions of RuboCop, may require this file to be generated ' \
         'again.',
         '',
         '# Offense count: 1',
         '# Cop supports --auto-correct.',
         '# Configuration parameters: EnforcedStyle, AllowInnerSlashes.',
         '# SupportedStyles: slashes, percent_r, mixed',
         'Style/RegexpLiteral:',
         '  Exclude:',
         "    - 'example.rb'"]
      actual = IO.read('.rubocop_todo.yml').split($RS)
      expected.each_with_index do |line, ix|
        if line.is_a?(String)
          expect(actual[ix]).to eq(line)
        else
          expect(actual[ix]).to match(line)
        end
      end
      expect(actual.size).to eq(expected.size)
      $stdout = StringIO.new
      result = cli.run(%w[--config .rubocop_todo.yml --format emacs])
      expect($stdout.string).to eq('')
      expect(result).to eq(0)
    end

    it 'does not include offense counts when --no-offense-counts is used' do
      create_file('example1.rb', ['$x= 0 ',
                                  '#' * 90,
                                  '#' * 85,
                                  'y ',
                                  'puts x'])
      create_file('example2.rb', <<-RUBY.strip_indent)
        # frozen_string_literal: true

        \tx = 0
        puts x

        class A
          def a; end
        end
      RUBY
      # Make ConfigLoader reload the default configuration so that its
      # absolute Exclude paths will point into this example's work directory.
      RuboCop::ConfigLoader.default_configuration = nil

      expect(cli.run(['--auto-gen-config', '--no-offense-counts'])).to eq(0)
      expect($stderr.string).to eq('')
      expect($stdout.string).to include('Created .rubocop_todo.yml.')
      expected =
        ['# This configuration was generated by',
         '# `rubocop --auto-gen-config --no-offense-counts`',
         /# on .* using RuboCop version .*/,
         '# The point is for the user to remove these configuration records',
         '# one by one as the offenses are removed from the code base.',
         '# Note that changes in the inspected code, or installation of new',
         '# versions of RuboCop, may require this file to be generated ' \
         'again.',
         '',
         '# Cop supports --auto-correct.',
         'Layout/CommentIndentation:',
         '  Exclude:',
         "    - 'example2.rb'",
         '',
         '# Cop supports --auto-correct.',
         '# Configuration parameters: EnforcedStyle.',
         '# SupportedStyles: normal, rails',
         'Layout/IndentationConsistency:',
         '  Exclude:',
         "    - 'example2.rb'",
         '',
         '# Cop supports --auto-correct.',
         'Layout/InitialIndentation:',
         '  Exclude:',
         "    - 'example2.rb'",
         '',
         '# Cop supports --auto-correct.',
         '# Configuration parameters: AllowForAlignment.',
         'Layout/SpaceAroundOperators:',
         '  Exclude:',
         "    - 'example1.rb'",
         '',
         '# Cop supports --auto-correct.',
         '# Configuration parameters: IndentationWidth.',
         'Layout/Tab:',
         '  Exclude:',
         "    - 'example2.rb'",
         '',
         '# Cop supports --auto-correct.',
         '# Configuration parameters: AllowInHeredoc.',
         'Layout/TrailingWhitespace:',
         '  Exclude:',
         "    - 'example1.rb'",
         '',
         'Style/Documentation:',
         '  Exclude:',
         "    - 'spec/**/*'", # Copied from default configuration
         "    - 'test/**/*'", # Copied from default configuration
         "    - 'example2.rb'",
         '',
         '# Configuration parameters: AllowedVariables.',
         'Style/GlobalVars:',
         '  Exclude:',
         "    - 'example1.rb'",
         '',
         '# Configuration parameters: AllowHeredoc, AllowURI, URISchemes, ' \
         'IgnoreCopDirectives, IgnoredPatterns.',
         '# URISchemes: http, https',
         'Metrics/LineLength:',
         '  Max: 90']
      actual = IO.read('.rubocop_todo.yml').split($RS)
      expected.each_with_index do |line, ix|
        if line.is_a?(String)
          expect(actual[ix]).to eq(line)
        else
          expect(actual[ix]).to match(line)
        end
      end
      expect(actual.size).to eq(expected.size)
    end

    it 'generates Exclude instead of Max when --auto-gen-only-exclude is' \
       ' used' do
      create_file('example1.rb', ['#' * 90,
                                  '#' * 90,
                                  'puts 123456'])
      create_file('example2.rb', <<-RUBY.strip_indent)
        def function(arg1, arg2, arg3, arg4, arg5, arg6, arg7)
          puts 123456
        end
      RUBY
      # Make ConfigLoader reload the default configuration so that its
      # absolute Exclude paths will point into this example's work directory.
      RuboCop::ConfigLoader.default_configuration = nil

      expect(cli.run(['--auto-gen-config', '--auto-gen-only-exclude',
                      '--exclude-limit', '1'])).to eq(0)
      actual = IO.read('.rubocop_todo.yml').split($RS)

      # With --exclude-limit 1 we get MinDigits generated for NumericLiterals
      # because there's one offense in each file. The other cops have offenses
      # in just one file, even though there may be more than one offense for
      # the same cop in a single file. Exclude properties are generated for
      # them.
      expect(actual.grep(/^[^#]/).join($RS)).to eq(<<-YAML.strip_indent.chomp)
        Lint/UnusedMethodArgument:
          Exclude:
            - 'example2.rb'
        Metrics/ParameterLists:
          Exclude:
            - 'example2.rb'
        Style/NumericLiterals:
          MinDigits: 7
        Metrics/LineLength:
          Exclude:
            - 'example1.rb'
      YAML
    end

    it 'does not include a timestamp when --no-auto-gen-timestamp is used' do
      create_file('example1.rb', ['$!'])
      expect(cli.run(['--auto-gen-config', '--no-auto-gen-timestamp'])).to eq(0)
      expect(IO.readlines('.rubocop_todo.yml')[2])
        .to match(/# using RuboCop version .*/)
    end

    describe 'when different styles appear in different files' do
      before do
        create_file('example1.rb', ['$!'])
        create_file('example2.rb', ['$!'])
        create_file('example3.rb', ['$ERROR_INFO'])
      end

      it 'disables cop if --exclude-limit is exceeded' do
        expect(cli.run(['--auto-gen-config', '--exclude-limit', '1'])).to eq(0)
        expect(IO.readlines('.rubocop_todo.yml')[8..-1].join)
          .to eq(<<-YAML.strip_indent)
            # Offense count: 2
            # Cop supports --auto-correct.
            # Configuration parameters: EnforcedStyle.
            # SupportedStyles: use_perl_names, use_english_names
            Style/SpecialGlobalVars:
              Enabled: false
          YAML
      end

      it 'generates Exclude list if --exclude-limit is not exceeded' do
        create_file('example4.rb', ['$!'])
        expect(cli.run(['--auto-gen-config', '--exclude-limit', '10'])).to eq(0)
        expect(IO.readlines('.rubocop_todo.yml')[8..-1].join)
          .to eq(<<-YAML.strip_indent)
            # Offense count: 3
            # Cop supports --auto-correct.
            # Configuration parameters: EnforcedStyle.
            # SupportedStyles: use_perl_names, use_english_names
            Style/SpecialGlobalVars:
              Exclude:
                - 'example1.rb'
                - 'example2.rb'
                - 'example4.rb'
          YAML
      end
    end

    describe 'console output' do
      before do
        create_file('example1.rb', ['$!'])
      end

      it 'displays report summary but no offenses' do
        expect(cli.run(['--auto-gen-config'])).to eq(0)

        expect($stdout.string).to include(<<-OUTPUT.strip_indent)
          Inspecting 1 file
          C

          1 file inspected, 1 offense detected
          Created .rubocop_todo.yml.
        OUTPUT
      end
    end

    it 'can be called when there are no files to inspection' do
      expect(cli.run(['--auto-gen-config'])).to eq(0)
    end
  end
end
