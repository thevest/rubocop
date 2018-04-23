# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails

      class DeprecatedQuery < Cop
        MSG = '`find(:first and find(:all` are deprecated, used `where` with chained methods.'.freeze

        def_node_matcher :find_options?, <<-PATTERN
          (send (const ...) :find (sym {:all :first :last}) (hash ...) ...)
        PATTERN

        def_node_matcher :count_options?, <<-PATTERN
          (send (const ...) :count (sym {:all}) (hash ...) ...)
        PATTERN

        def_node_matcher :paginate_options?, <<-PATTERN
          (send (const ...) :paginate (hash ...))
        PATTERN

        def on_send(node)
          return unless find_options?(node) || count_options?(node) || paginate_options?(node)
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

          if count_options?(node)
            new_expression += ".count"
          end

          lambda do |corrector|
            corrector.replace(node.loc.expression, new_expression)
          end
        end

        def make_method_chain(node)
          split_node = node.children[3]
          split_node = node.children[2] unless split_node
          chained_methods = split_node.child_nodes.map do |cnode|
            seperator = cnode.source.include?('=>') ? '=>' : ':'
            seperated = cnode.source.split(seperator, 2).map do |s|
              s.strip.gsub(/^:{1}/, '')
            end

            "#{seperated[0]}(#{seperated[1]})".gsub(/\A^conditions/, 'where').gsub(/\A^page/, "pagerize")
          end

          per_page_indx = chained_methods.index { |i| i.match(/A^per_page/) }
          chained_methods.delete_at(per_page_indx) if per_page_indx

          page_indx = chained_methods.index { |i| i.match(/A^pagerize/) }
          if page_indx && select_indx != chained_methods.count-1
            old = chained_methods[page_indx]
            chained_methods[page_indx] = chained_methods[1]
            chained_methods[chained_methods.count-1] = old
          end

          select_indx = chained_methods.index { |i| i.match(/A^select/) }
          if select_indx && select_indx != 1
            old = chained_methods[1]
            chained_methods[1] = chained_methods[select_indx]
            chained_methods[select_indx] = old
          end

          chained = chained_methods.join('.')

          chained
        end

      end
    end
  end
end

# corrector.replace(node.loc.selector, static_name)
# keywords.each.with_index do |keyword, idx|
#   corrector.insert_before(args[idx].loc.expression, keyword)
# end

# prev_email = BreadcrumbEmail.find(:first, conditions: ["user_id = ? and date(created_at) = ?", params[:id].to_i, Time.now.in_time_zone.to_date])

# 'awts = AssignableWorkType.find(:all, :conditions => ["deleted_id = 0 and id in (?)",params[:sort_order_ids].map(&:to_i)], :order => "field(id,#{params[:sort_order_ids].map(&:to_i).join(",")})")'
