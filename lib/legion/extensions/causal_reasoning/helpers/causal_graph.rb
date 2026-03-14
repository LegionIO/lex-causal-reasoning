# frozen_string_literal: true

module Legion
  module Extensions
    module CausalReasoning
      module Helpers
        class CausalGraph
          def initialize
            @variables  = {}
            @edges      = {}
            @edge_index = {}
          end

          def add_variable(name:, domain: :general)
            return nil if @variables.key?(name)
            return nil if @variables.size >= Constants::MAX_VARIABLES

            @variables[name] = { name: name, domain: domain, added_at: Time.now.utc }
          end

          def variable_exists?(name)
            @variables.key?(name)
          end

          def add_edge(cause:, effect:, edge_type:, domain: :general, strength: Constants::DEFAULT_STRENGTH)
            return nil if @edges.size >= Constants::MAX_EDGES
            return nil unless Constants::EDGE_TYPES.include?(edge_type)

            add_variable(name: cause, domain: domain)
            add_variable(name: effect, domain: domain)

            edge = CausalEdge.new(cause: cause, effect: effect,
                                  edge_type: edge_type, domain: domain, strength: strength)
            @edges[edge.id] = edge
            @edge_index[cause] ||= []
            @edge_index[cause] << edge.id
            edge
          end

          def remove_edge(edge_id:)
            edge = @edges.delete(edge_id)
            return nil unless edge

            @edge_index[edge.cause]&.delete(edge_id)
            edge
          end

          def causes_of(variable:)
            @edges.values.select { |e| e.effect == variable }
          end

          def effects_of(variable:)
            ids = @edge_index.fetch(variable, [])
            ids.filter_map { |id| @edges[id] }
          end

          def causal_chain(from:, to:, max_depth: 5)
            return [] if from == to

            queue   = [[from, [from]]]
            visited = { from => true }
            paths   = []

            until queue.empty?
              current, path = queue.shift
              next if path.size > max_depth + 1

              effects_of(variable: current).each do |edge|
                neighbor = edge.effect
                new_path = path + [neighbor]

                if neighbor == to
                  paths << new_path
                  next
                end

                next if visited[neighbor]

                visited[neighbor] = true
                queue << [neighbor, new_path]
              end
            end

            paths
          end

          def intervene(variable:, value:)
            downstream = []
            queue      = [variable]
            visited    = { variable => true }

            until queue.empty?
              current = queue.shift
              effects_of(variable: current).each do |edge|
                neighbor = edge.effect
                downstream << { variable: neighbor, via_edge: edge.id, edge_type: edge.edge_type }
                next if visited[neighbor]

                visited[neighbor] = true
                queue << neighbor
              end
            end

            { intervention: variable, value: value, downstream_effects: downstream }
          end

          def observe(variable:, value:, evidence:)
            affected = causes_of(variable: variable) + effects_of(variable: variable)
            affected.each { |edge| edge.add_evidence if evidence }
            { variable: variable, value: value, edges_updated: affected.size }
          end

          def confounders(var_a:, var_b:)
            ancestors_a = ancestors_of(var_a)
            ancestors_b = ancestors_of(var_b)
            common      = ancestors_a & ancestors_b
            common.reject { |v| v == var_a || v == var_b }
          end

          def add_evidence(edge_id:)
            edge = @edges[edge_id]
            return nil unless edge

            edge.add_evidence
          end

          def remove_evidence(edge_id:)
            edge = @edges[edge_id]
            return nil unless edge

            edge.remove_evidence
          end

          def confident_edges
            @edges.values.select(&:confident?)
          end

          def by_domain(domain:)
            @edges.values.select { |e| e.domain == domain }
          end

          def by_type(type:)
            @edges.values.select { |e| e.edge_type == type }
          end

          def decay_all
            @edges.each_value(&:decay)
            @edges.size
          end

          def prune_weak
            weak_ids = @edges.select { |_, e| e.strength <= Constants::STRENGTH_FLOOR }.keys
            weak_ids.each { |id| remove_edge(edge_id: id) }
            weak_ids.size
          end

          def to_h
            {
              variables:       @variables.size,
              edges:           @edges.size,
              confident_edges: confident_edges.size,
              edge_types:      Constants::EDGE_TYPES.to_h { |t| [t, by_type(type: t).size] }
            }
          end

          private

          def ancestors_of(variable, visited = {})
            return [] if visited[variable]

            visited[variable] = true
            direct_causes = causes_of(variable: variable).map(&:cause)
            indirect      = direct_causes.flat_map { |c| ancestors_of(c, visited) }
            (direct_causes + indirect).uniq
          end
        end
      end
    end
  end
end
