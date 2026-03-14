# frozen_string_literal: true

require 'legion/extensions/causal_reasoning/client'

RSpec.describe Legion::Extensions::CausalReasoning::Helpers::CausalGraph do
  subject(:graph) { described_class.new }

  let(:const) { Legion::Extensions::CausalReasoning::Helpers::Constants }

  def add_rain_wet(grph = graph)
    grph.add_edge(cause: :rain, effect: :wet_grass, edge_type: :causes, domain: :weather)
  end

  describe '#add_variable' do
    it 'registers a new variable and returns it' do
      var = graph.add_variable(name: :temperature, domain: :weather)
      expect(var[:name]).to eq(:temperature)
      expect(var[:domain]).to eq(:weather)
    end

    it 'returns nil for a duplicate variable name' do
      graph.add_variable(name: :temperature, domain: :weather)
      result = graph.add_variable(name: :temperature, domain: :weather)
      expect(result).to be_nil
    end
  end

  describe '#add_edge' do
    it 'creates and returns a CausalEdge' do
      edge = add_rain_wet
      expect(edge).to be_a(Legion::Extensions::CausalReasoning::Helpers::CausalEdge)
    end

    it 'auto-registers both cause and effect as variables' do
      add_rain_wet
      expect(graph.to_h[:variables]).to eq(2)
    end

    it 'returns nil for unknown edge_type' do
      result = graph.add_edge(cause: :a, effect: :b, edge_type: :unknown_type)
      expect(result).to be_nil
    end

    it 'accepts all valid EDGE_TYPES' do
      const::EDGE_TYPES.each_with_index do |type, idx|
        result = graph.add_edge(cause: :"cause_#{idx}", effect: :"effect_#{idx}", edge_type: type)
        expect(result).not_to be_nil
      end
    end
  end

  describe '#remove_edge' do
    it 'removes an existing edge and returns it' do
      edge    = add_rain_wet
      removed = graph.remove_edge(edge_id: edge.id)
      expect(removed.id).to eq(edge.id)
      expect(graph.to_h[:edges]).to eq(0)
    end

    it 'returns nil for unknown edge_id' do
      expect(graph.remove_edge(edge_id: 'nonexistent')).to be_nil
    end
  end

  describe '#causes_of' do
    it 'returns edges where the variable is the effect' do
      add_rain_wet
      causes = graph.causes_of(variable: :wet_grass)
      expect(causes.size).to eq(1)
      expect(causes.first.cause).to eq(:rain)
    end

    it 'returns empty array for variable with no causes' do
      expect(graph.causes_of(variable: :rain)).to be_empty
    end
  end

  describe '#effects_of' do
    it 'returns edges where the variable is the cause' do
      add_rain_wet
      effects = graph.effects_of(variable: :rain)
      expect(effects.size).to eq(1)
      expect(effects.first.effect).to eq(:wet_grass)
    end

    it 'returns empty array for unknown variable' do
      expect(graph.effects_of(variable: :unknown)).to be_empty
    end
  end

  describe '#causal_chain' do
    before do
      graph.add_edge(cause: :rain, effect: :wet_grass, edge_type: :causes)
      graph.add_edge(cause: :wet_grass, effect: :slippery_path, edge_type: :causes)
    end

    it 'finds a direct path between connected variables' do
      paths = graph.causal_chain(from: :rain, to: :slippery_path)
      expect(paths).not_to be_empty
      expect(paths.first).to eq(%i[rain wet_grass slippery_path])
    end

    it 'returns empty array when no path exists' do
      paths = graph.causal_chain(from: :slippery_path, to: :rain)
      expect(paths).to be_empty
    end

    it 'returns empty array when from == to' do
      paths = graph.causal_chain(from: :rain, to: :rain)
      expect(paths).to be_empty
    end

    it 'respects max_depth' do
      graph.add_edge(cause: :slippery_path, effect: :injury, edge_type: :causes)
      graph.add_edge(cause: :injury, effect: :hospital_visit, edge_type: :causes)
      paths = graph.causal_chain(from: :rain, to: :hospital_visit, max_depth: 2)
      expect(paths).to be_empty
    end
  end

  describe '#intervene' do
    before do
      graph.add_edge(cause: :smoking, effect: :cancer, edge_type: :causes)
      graph.add_edge(cause: :cancer, effect: :death, edge_type: :causes)
    end

    it 'returns the intervention variable and value' do
      result = graph.intervene(variable: :smoking, value: true)
      expect(result[:intervention]).to eq(:smoking)
      expect(result[:value]).to be true
    end

    it 'lists all downstream effects' do
      result = graph.intervene(variable: :smoking, value: true)
      variables = result[:downstream_effects].map { |e| e[:variable] }
      expect(variables).to include(:cancer, :death)
    end

    it 'returns empty downstream for leaf variable' do
      result = graph.intervene(variable: :death, value: true)
      expect(result[:downstream_effects]).to be_empty
    end
  end

  describe '#observe' do
    it 'updates edges involving the variable when evidence is true' do
      edge = add_rain_wet
      before_count = edge.evidence_count
      graph.observe(variable: :rain, value: true, evidence: true)
      expect(edge.evidence_count).to be > before_count
    end

    it 'returns the variable, value, and count of edges updated' do
      add_rain_wet
      result = graph.observe(variable: :rain, value: true, evidence: true)
      expect(result[:variable]).to eq(:rain)
      expect(result[:edges_updated]).to eq(1)
    end
  end

  describe '#confounders' do
    it 'finds common ancestors of two variables' do
      graph.add_edge(cause: :weather, effect: :rain, edge_type: :causes)
      graph.add_edge(cause: :weather, effect: :cold, edge_type: :causes)
      common = graph.confounders(var_a: :rain, var_b: :cold)
      expect(common).to include(:weather)
    end

    it 'returns empty array when no confounders exist' do
      graph.add_edge(cause: :a, effect: :b, edge_type: :causes)
      graph.add_edge(cause: :c, effect: :d, edge_type: :causes)
      expect(graph.confounders(var_a: :b, var_b: :d)).to be_empty
    end
  end

  describe '#add_evidence and #remove_evidence' do
    it 'delegates add_evidence to the edge' do
      edge = add_rain_wet
      graph.add_evidence(edge_id: edge.id)
      expect(edge.evidence_count).to eq(1)
    end

    it 'returns nil for unknown edge_id in add_evidence' do
      expect(graph.add_evidence(edge_id: 'bad_id')).to be_nil
    end

    it 'delegates remove_evidence to the edge' do
      edge = add_rain_wet
      edge.add_evidence
      graph.remove_evidence(edge_id: edge.id)
      expect(edge.evidence_count).to eq(0)
    end
  end

  describe '#confident_edges' do
    it 'returns only edges meeting confidence threshold' do
      edge = add_rain_wet
      3.times { edge.add_evidence }
      edge.reinforce(amount: 0.2)
      expect(graph.confident_edges).to include(edge)
    end

    it 'excludes edges below threshold' do
      add_rain_wet
      expect(graph.confident_edges).to be_empty
    end
  end

  describe '#by_domain and #by_type' do
    before do
      graph.add_edge(cause: :rain, effect: :wet_grass, edge_type: :causes, domain: :weather)
      graph.add_edge(cause: :stress, effect: :illness, edge_type: :causes, domain: :health)
    end

    it 'filters edges by domain' do
      expect(graph.by_domain(domain: :weather).size).to eq(1)
      expect(graph.by_domain(domain: :health).size).to eq(1)
    end

    it 'filters edges by type' do
      expect(graph.by_type(type: :causes).size).to eq(2)
      expect(graph.by_type(type: :prevents).size).to eq(0)
    end
  end

  describe '#decay_all' do
    it 'decays all edges and returns total count' do
      add_rain_wet
      result = graph.decay_all
      expect(result).to eq(1)
    end
  end

  describe '#prune_weak' do
    it 'removes edges at STRENGTH_FLOOR and returns count' do
      edge = add_rain_wet
      100.times { edge.weaken }
      pruned = graph.prune_weak
      expect(pruned).to eq(1)
      expect(graph.to_h[:edges]).to eq(0)
    end

    it 'returns 0 when no weak edges exist' do
      add_rain_wet
      expect(graph.prune_weak).to eq(0)
    end
  end

  describe '#to_h' do
    it 'returns stats hash with variables, edges, confident_edges, edge_types' do
      add_rain_wet
      stats = graph.to_h
      expect(stats[:variables]).to eq(2)
      expect(stats[:edges]).to eq(1)
      expect(stats[:edge_types]).to be_a(Hash)
      expect(stats[:edge_types][:causes]).to eq(1)
    end
  end
end
