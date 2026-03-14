# frozen_string_literal: true

require 'legion/extensions/causal_reasoning/client'

RSpec.describe Legion::Extensions::CausalReasoning::Helpers::CausalEdge do
  subject(:edge) do
    described_class.new(cause: :rain, effect: :wet_grass, edge_type: :causes, domain: :weather)
  end

  describe '#initialize' do
    it 'sets cause and effect' do
      expect(edge.cause).to eq(:rain)
      expect(edge.effect).to eq(:wet_grass)
    end

    it 'sets edge_type and domain' do
      expect(edge.edge_type).to eq(:causes)
      expect(edge.domain).to eq(:weather)
    end

    it 'clamps strength to STRENGTH_FLOOR..STRENGTH_CEILING' do
      over  = described_class.new(cause: :a, effect: :b, edge_type: :causes, strength: 2.0)
      under = described_class.new(cause: :a, effect: :b, edge_type: :causes, strength: 0.0)
      expect(over.strength).to eq(Legion::Extensions::CausalReasoning::Helpers::Constants::STRENGTH_CEILING)
      expect(under.strength).to eq(Legion::Extensions::CausalReasoning::Helpers::Constants::STRENGTH_FLOOR)
    end

    it 'starts with evidence_count of zero' do
      expect(edge.evidence_count).to eq(0)
    end

    it 'assigns a unique id' do
      other = described_class.new(cause: :rain, effect: :wet_grass, edge_type: :causes)
      expect(edge.id).not_to eq(other.id)
    end
  end

  describe '#add_evidence' do
    it 'increments evidence_count' do
      edge.add_evidence
      expect(edge.evidence_count).to eq(1)
    end

    it 'increases strength' do
      before = edge.strength
      edge.add_evidence
      expect(edge.strength).to be > before
    end

    it 'returns self' do
      expect(edge.add_evidence).to be(edge)
    end

    it 'does not exceed STRENGTH_CEILING' do
      100.times { edge.add_evidence }
      expect(edge.strength).to eq(Legion::Extensions::CausalReasoning::Helpers::Constants::STRENGTH_CEILING)
    end
  end

  describe '#remove_evidence' do
    it 'decrements evidence_count but not below zero' do
      edge.remove_evidence
      expect(edge.evidence_count).to eq(0)
    end

    it 'decreases strength' do
      before = edge.strength
      edge.remove_evidence
      expect(edge.strength).to be < before
    end

    it 'does not go below STRENGTH_FLOOR' do
      100.times { edge.remove_evidence }
      expect(edge.strength).to eq(Legion::Extensions::CausalReasoning::Helpers::Constants::STRENGTH_FLOOR)
    end
  end

  describe '#reinforce' do
    it 'increases strength by given amount' do
      before = edge.strength
      edge.reinforce(amount: 0.2)
      expect(edge.strength).to be_within(0.001).of(before + 0.2)
    end

    it 'clamps at STRENGTH_CEILING' do
      edge.reinforce(amount: 1.0)
      expect(edge.strength).to eq(Legion::Extensions::CausalReasoning::Helpers::Constants::STRENGTH_CEILING)
    end
  end

  describe '#weaken' do
    it 'decreases strength by given amount' do
      before = edge.strength
      edge.weaken(amount: 0.1)
      expect(edge.strength).to be_within(0.001).of(before - 0.1)
    end

    it 'clamps at STRENGTH_FLOOR' do
      edge.weaken(amount: 1.0)
      expect(edge.strength).to eq(Legion::Extensions::CausalReasoning::Helpers::Constants::STRENGTH_FLOOR)
    end
  end

  describe '#decay' do
    it 'reduces strength by DECAY_RATE' do
      before = edge.strength
      edge.decay
      expect(edge.strength).to be_within(0.001).of(before - Legion::Extensions::CausalReasoning::Helpers::Constants::DECAY_RATE)
    end

    it 'does not go below STRENGTH_FLOOR' do
      100.times { edge.decay }
      expect(edge.strength).to eq(Legion::Extensions::CausalReasoning::Helpers::Constants::STRENGTH_FLOOR)
    end
  end

  describe '#confident?' do
    it 'returns false when evidence_count is below EVIDENCE_THRESHOLD' do
      expect(edge.confident?).to be false
    end

    it 'returns true when both strength and evidence_count meet thresholds' do
      3.times { edge.add_evidence }
      edge.reinforce(amount: 0.2)
      expect(edge.confident?).to be true
    end
  end

  describe '#confidence_label' do
    it 'returns :speculative for low strength' do
      edge.weaken(amount: 1.0)
      expect(edge.confidence_label).to eq(:speculative)
    end

    it 'returns :moderate for strength around 0.7' do
      strong_edge = described_class.new(cause: :a, effect: :b, edge_type: :causes, strength: 0.7)
      expect(strong_edge.confidence_label).to eq(:moderate)
    end

    it 'returns :strong for strength >= 0.8' do
      strong_edge = described_class.new(cause: :a, effect: :b, edge_type: :causes, strength: 0.9)
      expect(strong_edge.confidence_label).to eq(:strong)
    end
  end

  describe '#to_h' do
    it 'includes all key fields' do
      hash = edge.to_h
      expect(hash).to include(:id, :cause, :effect, :edge_type, :domain,
                              :strength, :evidence_count, :confident, :label,
                              :created_at, :updated_at)
    end

    it 'reflects confident? state' do
      expect(edge.to_h[:confident]).to be false
    end
  end
end
