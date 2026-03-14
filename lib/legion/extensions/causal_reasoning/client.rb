# frozen_string_literal: true

require 'legion/extensions/causal_reasoning/helpers/constants'
require 'legion/extensions/causal_reasoning/helpers/causal_edge'
require 'legion/extensions/causal_reasoning/helpers/causal_graph'
require 'legion/extensions/causal_reasoning/runners/causal_reasoning'

module Legion
  module Extensions
    module CausalReasoning
      class Client
        include Runners::CausalReasoning

        def initialize(graph: nil, **)
          @graph = graph
        end
      end
    end
  end
end
