# frozen_string_literal: true

module Legion
  module Extensions
    module CausalReasoning
      module Helpers
        module Constants
          MAX_VARIABLES = 200
          MAX_EDGES     = 500
          MAX_HISTORY   = 300

          DEFAULT_STRENGTH  = 0.5
          STRENGTH_FLOOR    = 0.05
          STRENGTH_CEILING  = 0.95

          EVIDENCE_THRESHOLD = 3
          CAUSAL_THRESHOLD   = 0.6

          REINFORCEMENT_RATE = 0.1
          DECAY_RATE         = 0.01

          EDGE_TYPES      = %i[causes prevents enables inhibits modulates].freeze
          INFERENCE_TYPES = %i[observation intervention counterfactual].freeze

          CONFIDENCE_LABELS = {
            (0.8..)     => :strong,
            (0.6...0.8) => :moderate,
            (0.4...0.6) => :weak,
            (0.2...0.4) => :tentative,
            (..0.2)     => :speculative
          }.freeze
        end
      end
    end
  end
end
