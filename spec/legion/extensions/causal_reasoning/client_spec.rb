# frozen_string_literal: true

require 'legion/extensions/causal_reasoning/client'

RSpec.describe Legion::Extensions::CausalReasoning::Client do
  let(:client) { described_class.new }

  it 'responds to all runner methods' do
    expect(client).to respond_to(:add_causal_variable)
    expect(client).to respond_to(:add_causal_edge)
    expect(client).to respond_to(:find_causes)
    expect(client).to respond_to(:find_effects)
    expect(client).to respond_to(:trace_causal_chain)
    expect(client).to respond_to(:causal_intervention)
    expect(client).to respond_to(:find_confounders)
    expect(client).to respond_to(:add_causal_evidence)
    expect(client).to respond_to(:update_causal_reasoning)
    expect(client).to respond_to(:causal_reasoning_stats)
  end

  it 'accepts an injected graph' do
    injected_graph = Legion::Extensions::CausalReasoning::Helpers::CausalGraph.new
    injected_graph.add_edge(cause: :a, effect: :b, edge_type: :causes)
    client_with_graph = described_class.new(graph: injected_graph)
    result = client_with_graph.causal_reasoning_stats
    expect(result[:edges]).to eq(1)
  end

  it 'maintains isolated state between instances' do
    c1 = described_class.new
    c2 = described_class.new
    c1.add_causal_edge(cause: :a, effect: :b, edge_type: :causes)
    expect(c2.causal_reasoning_stats[:edges]).to eq(0)
  end
end
