# lex-causal-reasoning

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Causal inference engine for brain-modeled agentic AI — do-calculus and causal graphs. Models causal relationships between variables as a directed graph, supporting observational inference (what correlates), interventional inference (do-calculus: what happens when we force a variable), counterfactual reasoning (what would have happened if), and confounder detection.

## Gem Info

- **Gem name**: `lex-causal-reasoning`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::CausalReasoning`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/causal_reasoning/
  causal_reasoning.rb            # Main extension module
  version.rb                     # VERSION = '0.1.0'
  client.rb                      # Client wrapper
  helpers/
    constants.rb                 # Limits, thresholds, edge types, inference types, labels
    causal_edge.rb               # CausalEdge value object (strength, evidence_count, type)
    causal_graph.rb              # CausalGraph — variable registry, edge management, inference
  runners/
    causal_reasoning.rb          # Runner module with 9 public methods
spec/
  (spec files)
```

## Key Constants

```ruby
MAX_VARIABLES      = 200
MAX_EDGES          = 500
MAX_HISTORY        = 300
DEFAULT_STRENGTH   = 0.5
STRENGTH_FLOOR     = 0.05
STRENGTH_CEILING   = 0.95
EVIDENCE_THRESHOLD = 3       # edges strengthen significantly after 3 supporting evidences
CAUSAL_THRESHOLD   = 0.6     # minimum strength for a "confident" causal claim
REINFORCEMENT_RATE = 0.1
DECAY_RATE         = 0.01
EDGE_TYPES      = %i[causes prevents enables inhibits modulates]
INFERENCE_TYPES = %i[observation intervention counterfactual]
CONFIDENCE_LABELS = {
  (0.8..) => :strong, (0.6...0.8) => :moderate,
  (0.4...0.6) => :weak, (0.2...0.4) => :tentative, (..0.2) => :speculative
}
```

## Runners

### `Runners::CausalReasoning`

All methods delegate to a private `@graph` (`Helpers::CausalGraph` instance).

- `add_causal_variable(name:, domain: :general)` — register a variable in the causal graph
- `add_causal_edge(cause:, effect:, edge_type:, domain: :general, strength: DEFAULT_STRENGTH)` — add a causal link between variables
- `find_causes(variable:)` — find all causal edges pointing to this variable
- `find_effects(variable:)` — find all causal edges emanating from this variable
- `trace_causal_chain(from:, to:, max_depth: 5)` — find all causal paths between two variables (BFS/DFS up to max_depth)
- `causal_intervention(variable:, value:)` — do-calculus intervention: force a variable to a value and compute downstream effects
- `find_confounders(var_a:, var_b:)` — find common causes of two variables
- `add_causal_evidence(edge_id:)` — strengthen an edge by adding supporting evidence
- `update_causal_reasoning` — decay weak edges, prune below floor
- `causal_reasoning_stats` — stats hash

## Helpers

### `Helpers::CausalGraph`
Core engine managing `@variables` and `@edges` hashes. `causal_chain` performs depth-limited path search. `intervene` applies do-calculus by forcing a variable's value and traversing downstream effects through the edge types. `confounders` finds variables that are causes of both `var_a` and `var_b`. `prune_weak` removes edges below `STRENGTH_FLOOR`.

### `Helpers::CausalEdge`
Value object: cause, effect, edge_type, domain, strength, evidence_count. `add_evidence!` increases strength by `REINFORCEMENT_RATE`. `confidence_label` maps strength to labels.

## Integration Points

No actor defined — callers drive decay via `update_causal_reasoning`. This is a core reasoning substrate. Pairs with lex-bayesian-belief (causal graph edges can be associated with beliefs), lex-abductive-reasoning (best explanations map to causal structures), and lex-analogical-reasoning (analogies often transfer causal structures between domains). `causal_intervention` is the foundation for counterfactual reasoning: "if we had done X, Y would have happened."

## Development Notes

- `variable_exists?` check in `add_causal_variable` prevents duplicates without raising an error
- Edge strength is initialized at `DEFAULT_STRENGTH` and updated via evidence; callers can also pass an explicit `strength:` at creation
- `trace_causal_chain` returns an array of paths (each path is an array of variables); empty array means no path found within max_depth
- `causal_intervention` currently returns the set of downstream effects with their edge types — the caller must interpret the downstream implications
