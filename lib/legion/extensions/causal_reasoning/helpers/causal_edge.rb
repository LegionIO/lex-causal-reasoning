# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module CausalReasoning
      module Helpers
        class CausalEdge
          include Constants

          attr_reader :id, :cause, :effect, :edge_type, :domain, :evidence_count, :created_at, :updated_at, :strength

          def initialize(cause:, effect:, edge_type:, domain: :general, strength: Constants::DEFAULT_STRENGTH)
            @id             = SecureRandom.uuid
            @cause          = cause
            @effect         = effect
            @edge_type      = edge_type
            @domain         = domain
            @strength       = strength.clamp(Constants::STRENGTH_FLOOR, Constants::STRENGTH_CEILING)
            @evidence_count = 0
            @created_at     = Time.now.utc
            @updated_at     = Time.now.utc
          end

          def add_evidence
            @evidence_count += 1
            @strength = (@strength + Constants::REINFORCEMENT_RATE).clamp(
              Constants::STRENGTH_FLOOR, Constants::STRENGTH_CEILING
            )
            @updated_at = Time.now.utc
            self
          end

          def remove_evidence
            @evidence_count = [@evidence_count - 1, 0].max
            @strength = (@strength - Constants::REINFORCEMENT_RATE).clamp(
              Constants::STRENGTH_FLOOR, Constants::STRENGTH_CEILING
            )
            @updated_at = Time.now.utc
            self
          end

          def reinforce(amount: Constants::REINFORCEMENT_RATE)
            @strength = (@strength + amount).clamp(
              Constants::STRENGTH_FLOOR, Constants::STRENGTH_CEILING
            )
            @updated_at = Time.now.utc
            self
          end

          def weaken(amount: Constants::REINFORCEMENT_RATE)
            @strength = (@strength - amount).clamp(
              Constants::STRENGTH_FLOOR, Constants::STRENGTH_CEILING
            )
            @updated_at = Time.now.utc
            self
          end

          def decay
            @strength = (@strength - Constants::DECAY_RATE).clamp(
              Constants::STRENGTH_FLOOR, Constants::STRENGTH_CEILING
            )
            @updated_at = Time.now.utc
            self
          end

          def confident?
            @strength >= Constants::CAUSAL_THRESHOLD &&
              @evidence_count >= Constants::EVIDENCE_THRESHOLD
          end

          def confidence_label
            match = Constants::CONFIDENCE_LABELS.find { |range, _| range.cover?(@strength) }
            match ? match[1] : :speculative
          end

          def to_h
            {
              id:             @id,
              cause:          @cause,
              effect:         @effect,
              edge_type:      @edge_type,
              domain:         @domain,
              strength:       @strength,
              evidence_count: @evidence_count,
              confident:      confident?,
              label:          confidence_label,
              created_at:     @created_at,
              updated_at:     @updated_at
            }
          end
        end
      end
    end
  end
end
