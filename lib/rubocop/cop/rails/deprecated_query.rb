# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails

      class DeprecatedQuery < Cop
        MSG = '`find(:first and find(:all` are deprecated, used `where` with chained methods.'.freeze

        def_node_matcher :find_options?, <<-PATTERN
          (send (const ...) :find (sym {:all :first :last}) (hash ...) ...)
        PATTERN

        def on_send(node)
          return unless find_options?(node)
          add_offense(node)
        end

        def autocorrect(node)
          _receiver, method, *args = *node

          model_call = node.children[0].source

          find_type = node.children[2].source

          chained_methods = make_method_chain(node)

          new_expression =
            if find_type == ":first"
              "#{model_call}.#{chained_methods}.first"
            elsif find_type == ":last"
              "#{model_call}.#{chained_methods}.last"
            else
              "#{model_call}.#{chained_methods}"
            end

          lambda do |corrector|
            corrector.replace(node.loc.expression, new_expression)
          end
        end

        def make_method_chain(node)
          chained_methods = node.children[3].child_nodes.map do |cnode|
            seperator = cnode.source.include?('=>') ? '=>' : ':'
            seperated = cnode.source.split(seperator).map do |s|
              s.strip.gsub(/^:{1}/, '')
            end
            "#{seperated[0]}(#{seperated[1]})".gsub(/\A^conditions/, 'where')
          end

          select_indx = chained_methods.index { |i| i.match(/A^select/) }
          if select_indx && select_indx != 1
            old = chained_methods[1]
            chained_methods[1] = chained_methods[select_indx]
            chained_methods[select_indx] = old
          end

          chained_methods.join('.')
        end

      end
    end
  end
end

# corrector.replace(node.loc.selector, static_name)
# keywords.each.with_index do |keyword, idx|
#   corrector.insert_before(args[idx].loc.expression, keyword)
# end
