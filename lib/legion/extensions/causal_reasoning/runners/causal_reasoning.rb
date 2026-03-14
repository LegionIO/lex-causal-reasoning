# frozen_string_literal: true

module Legion
  module Extensions
    module CausalReasoning
      module Runners
        module CausalReasoning
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def add_causal_variable(name:, domain: :general, **)
            if graph.variable_exists?(name)
              Legion::Logging.warn "[causal] add_variable duplicate: name=#{name}"
              return { success: false, reason: :limit_or_duplicate, name: name }
            end

            variable = graph.add_variable(name: name, domain: domain)
            if variable
              Legion::Logging.debug "[causal] add_variable: name=#{name} domain=#{domain}"
              { success: true, variable: variable }
            else
              Legion::Logging.warn "[causal] add_variable failed (limit): name=#{name}"
              { success: false, reason: :limit_or_duplicate, name: name }
            end
          end

          def add_causal_edge(cause:, effect:, edge_type:, domain: :general,
                              strength: Helpers::Constants::DEFAULT_STRENGTH, **)
            edge = graph.add_edge(cause: cause, effect: effect,
                                  edge_type: edge_type, domain: domain, strength: strength)
            if edge
              str = edge.strength.round(2)
              Legion::Logging.debug "[causal] add_edge: #{cause}->#{effect} type=#{edge_type} str=#{str}"
              { success: true, edge: edge.to_h }
            else
              Legion::Logging.warn "[causal] add_edge failed: cause=#{cause} effect=#{effect} type=#{edge_type}"
              { success: false, reason: :limit_or_invalid_type, cause: cause, effect: effect }
            end
          end

          def find_causes(variable:, **)
            edges = graph.causes_of(variable: variable)
            Legion::Logging.debug "[causal] find_causes: variable=#{variable} count=#{edges.size}"
            { success: true, variable: variable, causes: edges.map(&:to_h), count: edges.size }
          end

          def find_effects(variable:, **)
            edges = graph.effects_of(variable: variable)
            Legion::Logging.debug "[causal] find_effects: variable=#{variable} count=#{edges.size}"
            { success: true, variable: variable, effects: edges.map(&:to_h), count: edges.size }
          end

          def trace_causal_chain(from:, to:, max_depth: 5, **)
            paths = graph.causal_chain(from: from, to: to, max_depth: max_depth)
            Legion::Logging.debug "[causal] trace_chain: from=#{from} to=#{to} paths=#{paths.size}"
            { success: true, from: from, to: to, paths: paths, path_count: paths.size }
          end

          def causal_intervention(variable:, value:, **)
            result = graph.intervene(variable: variable, value: value)
            count = result[:downstream_effects].size
            Legion::Logging.info "[causal] intervention: do(#{variable}=#{value}) downstream=#{count}"
            { success: true }.merge(result)
          end

          def find_confounders(var_a:, var_b:, **)
            common = graph.confounders(var_a: var_a, var_b: var_b)
            Legion::Logging.debug "[causal] confounders: #{var_a} <-> #{var_b} count=#{common.size}"
            { success: true, var_a: var_a, var_b: var_b, confounders: common, count: common.size }
          end

          def add_causal_evidence(edge_id:, **)
            edge = graph.add_evidence(edge_id: edge_id)
            if edge
              cnt = edge.evidence_count
              str = edge.strength.round(2)
              Legion::Logging.debug "[causal] add_evidence: edge=#{edge_id} count=#{cnt} strength=#{str}"
              { success: true, edge_id: edge_id, evidence_count: edge.evidence_count, strength: edge.strength }
            else
              Legion::Logging.warn "[causal] add_evidence failed: edge=#{edge_id} not found"
              { success: false, reason: :edge_not_found, edge_id: edge_id }
            end
          end

          def update_causal_reasoning(**)
            decayed = graph.decay_all
            pruned  = graph.prune_weak
            Legion::Logging.debug "[causal] update: decayed=#{decayed} pruned=#{pruned}"
            { success: true, decayed: decayed, pruned: pruned }
          end

          def causal_reasoning_stats(**)
            stats = graph.to_h
            Legion::Logging.debug "[causal] stats: #{stats.inspect}"
            { success: true }.merge(stats)
          end

          private

          def graph
            @graph ||= Helpers::CausalGraph.new
          end
        end
      end
    end
  end
end
