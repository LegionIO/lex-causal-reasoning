# frozen_string_literal: true

require_relative 'lib/legion/extensions/causal_reasoning/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-causal-reasoning'
  spec.version       = Legion::Extensions::CausalReasoning::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Causal Reasoning'
  spec.description   = 'Causal inference engine for brain-modeled agentic AI — do-calculus and causal graphs'
  spec.homepage      = 'https://github.com/LegionIO/lex-causal-reasoning'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-causal-reasoning'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-causal-reasoning'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-causal-reasoning'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-causal-reasoning/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-causal-reasoning.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
end
