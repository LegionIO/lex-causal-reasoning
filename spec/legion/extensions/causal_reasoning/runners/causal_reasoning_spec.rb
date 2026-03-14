# frozen_string_literal: true

require 'legion/extensions/causal_reasoning/client'

RSpec.describe Legion::Extensions::CausalReasoning::Runners::CausalReasoning do
  let(:client) { Legion::Extensions::CausalReasoning::Client.new }

  describe '#add_causal_variable' do
    it 'returns success: true and the variable hash' do
      result = client.add_causal_variable(name: :temperature, domain: :weather)
      expect(result[:success]).to be true
      expect(result[:variable][:name]).to eq(:temperature)
    end

    it 'returns success: false for duplicate variable' do
      client.add_causal_variable(name: :temperature, domain: :weather)
      result = client.add_causal_variable(name: :temperature, domain: :weather)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:limit_or_duplicate)
    end
  end

  describe '#add_causal_edge' do
    it 'returns success: true and an edge hash' do
      result = client.add_causal_edge(cause: :rain, effect: :wet_grass, edge_type: :causes)
      expect(result[:success]).to be true
      expect(result[:edge][:cause]).to eq(:rain)
      expect(result[:edge][:effect]).to eq(:wet_grass)
    end

    it 'returns success: false for invalid edge_type' do
      result = client.add_causal_edge(cause: :a, effect: :b, edge_type: :unknown)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:limit_or_invalid_type)
    end

    it 'uses given strength' do
      result = client.add_causal_edge(cause: :a, effect: :b, edge_type: :causes, strength: 0.8)
      expect(result[:edge][:strength]).to be_within(0.001).of(0.8)
    end
  end

  describe '#find_causes' do
    it 'returns causes of a variable' do
      client.add_causal_edge(cause: :rain, effect: :wet_grass, edge_type: :causes)
      result = client.find_causes(variable: :wet_grass)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
      expect(result[:causes].first[:cause]).to eq(:rain)
    end

    it 'returns empty causes for variable with no incoming edges' do
      client.add_causal_edge(cause: :rain, effect: :wet_grass, edge_type: :causes)
      result = client.find_causes(variable: :rain)
      expect(result[:count]).to eq(0)
    end
  end

  describe '#find_effects' do
    it 'returns effects of a variable' do
      client.add_causal_edge(cause: :rain, effect: :wet_grass, edge_type: :causes)
      result = client.find_effects(variable: :rain)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
      expect(result[:effects].first[:effect]).to eq(:wet_grass)
    end

    it 'returns empty effects for leaf variable' do
      client.add_causal_edge(cause: :rain, effect: :wet_grass, edge_type: :causes)
      result = client.find_effects(variable: :wet_grass)
      expect(result[:count]).to eq(0)
    end
  end

  describe '#trace_causal_chain' do
    before do
      client.add_causal_edge(cause: :rain, effect: :wet_grass, edge_type: :causes)
      client.add_causal_edge(cause: :wet_grass, effect: :slippery, edge_type: :causes)
    end

    it 'finds a multi-hop causal path' do
      result = client.trace_causal_chain(from: :rain, to: :slippery)
      expect(result[:success]).to be true
      expect(result[:path_count]).to be >= 1
    end

    it 'returns zero paths when no connection' do
      result = client.trace_causal_chain(from: :slippery, to: :rain)
      expect(result[:path_count]).to eq(0)
    end
  end

  describe '#causal_intervention' do
    before do
      client.add_causal_edge(cause: :smoking, effect: :cancer, edge_type: :causes)
      client.add_causal_edge(cause: :cancer, effect: :treatment, edge_type: :causes)
    end

    it 'returns success: true and lists downstream effects' do
      result = client.causal_intervention(variable: :smoking, value: true)
      expect(result[:success]).to be true
      expect(result[:intervention]).to eq(:smoking)
      downstream_vars = result[:downstream_effects].map { |e| e[:variable] }
      expect(downstream_vars).to include(:cancer, :treatment)
    end
  end

  describe '#find_confounders' do
    before do
      client.add_causal_edge(cause: :weather, effect: :rain, edge_type: :causes)
      client.add_causal_edge(cause: :weather, effect: :cold, edge_type: :causes)
    end

    it 'identifies common ancestors as confounders' do
      result = client.find_confounders(var_a: :rain, var_b: :cold)
      expect(result[:success]).to be true
      expect(result[:confounders]).to include(:weather)
    end

    it 'returns empty confounders for unrelated variables' do
      result = client.find_confounders(var_a: :rain, var_b: :unrelated)
      expect(result[:count]).to eq(0)
    end
  end

  describe '#add_causal_evidence' do
    it 'increments evidence on an existing edge' do
      edge_result = client.add_causal_edge(cause: :rain, effect: :wet_grass, edge_type: :causes)
      edge_id     = edge_result[:edge][:id]
      result      = client.add_causal_evidence(edge_id: edge_id)
      expect(result[:success]).to be true
      expect(result[:evidence_count]).to eq(1)
    end

    it 'returns success: false for unknown edge_id' do
      result = client.add_causal_evidence(edge_id: 'nonexistent-uuid')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:edge_not_found)
    end
  end

  describe '#update_causal_reasoning' do
    it 'returns success: true with decayed and pruned counts' do
      client.add_causal_edge(cause: :rain, effect: :wet_grass, edge_type: :causes)
      result = client.update_causal_reasoning
      expect(result[:success]).to be true
      expect(result[:decayed]).to eq(1)
      expect(result[:pruned]).to eq(0)
    end
  end

  describe '#causal_reasoning_stats' do
    it 'returns stats including variables and edges counts' do
      client.add_causal_edge(cause: :rain, effect: :wet_grass, edge_type: :causes)
      result = client.causal_reasoning_stats
      expect(result[:success]).to be true
      expect(result[:variables]).to eq(2)
      expect(result[:edges]).to eq(1)
    end
  end
end
