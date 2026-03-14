# lex-causal-reasoning

Causal inference engine for brain-modeled agentic AI — do-calculus and causal graphs.

## What It Does

Builds and reasons over a causal graph of variables and relationships. Supports three types of inference: observational (what correlates with what), interventional (do-calculus: what happens when we force a variable to a value), and counterfactual (what would have happened under different conditions). Detects confounders, traces multi-hop causal chains, and strengthens edges with evidence.

## Core Concept: The Causal Graph

Variables are nodes; causal relationships are typed directed edges (`causes`, `prevents`, `enables`, `inhibits`, `modulates`). Do-calculus (`causal_intervention`) breaks the normal causal structure and forces a variable to a value:

```
do(X = true) → what downstream variables are affected?
```

## Usage

```ruby
client = Legion::Extensions::CausalReasoning::Client.new

# Build a causal graph
client.add_causal_variable(name: :high_traffic, domain: :infrastructure)
client.add_causal_variable(name: :cache_miss, domain: :infrastructure)
client.add_causal_variable(name: :high_latency, domain: :infrastructure)

edge = client.add_causal_edge(
  cause: :high_traffic, effect: :cache_miss, edge_type: :causes, strength: 0.8
)
client.add_causal_edge(cause: :cache_miss, effect: :high_latency, edge_type: :causes)

# Add evidence to strengthen the edge
client.add_causal_evidence(edge_id: edge[:edge][:id])

# Trace the full causal chain
client.trace_causal_chain(from: :high_traffic, to: :high_latency)
# => { paths: [[:high_traffic, :cache_miss, :high_latency]], path_count: 1 }

# Intervene: what if we force cache_miss to false?
client.causal_intervention(variable: :cache_miss, value: false)
# => { downstream_effects: [{ variable: :high_latency, edge_type: :causes }] }

# Find common causes
client.find_confounders(var_a: :high_latency, var_b: :errors)
```

## Integration

Pairs with lex-abductive-reasoning (best explanations map to causal structures) and lex-analogical-reasoning (analogies transfer causal structures between domains). `causal_intervention` supports counterfactual reasoning for post-incident analysis.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
