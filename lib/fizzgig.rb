require 'puppet'
require 'fizzgig/matchers'
require 'fizzgig/function_stubs'
require 'lspace'

module Fizzgig
  def self.instantiate(code,options = {})
    LSpace.with(:function_stubs => options[:stubs]) do
      setup_puppet
      compiler = make_compiler(options[:facts])
      resources = compile(code,compiler)
      resources[0].evaluate
      compiler.catalog
    end
  end

  def self.include(klass,options = {})
    LSpace.with(:function_stubs => options[:stubs]) do
      setup_puppet
      compiler = make_compiler(options[:facts])
      compile("include #{klass}",compiler)
      compiler.catalog
    end
  end

  def self.node(hostname,options = {})
    LSpace.with(:function_stubs => options[:stubs]) do
      setup_puppet
      Puppet[:code] = '' # we want puppet to import the Puppet[:manifest] file
      compiler = make_compiler(options[:facts], hostname)
      compiler.send :evaluate_ast_node
      compiler.catalog
    end
  end

  def self.make_compiler(facts,hostname='localhost')
    node = Puppet::Node.new(hostname)
    node.merge(facts) if facts
    compiler = Puppet::Parser::Compiler.new(node)
    compiler.send :set_node_parameters
    compiler.send :evaluate_main
    compiler
  end

  def self.compile(code,compiler)
    resources_for(ast_for(code,compiler),compiler)
  end

  def self.resources_for(ast,compiler)
    scope = compiler.newscope(nil)
    scope.source = Puppet::Resource::Type.new(:node,'localhost')
    ast.code[0].evaluate(scope)
  end

  def self.ast_for(code,compiler)
    parser = Puppet::Parser::Parser.new compiler.environment.name
    parser.parse(code)
  end

  def self.setup_puppet
    Puppet[:code] = ' ' # hack to suppress puppet from looking at Puppet[:manifest]
    Puppet[:modulepath] = RSpec.configuration.modulepath
    Puppet[:manifestdir] = RSpec.configuration.manifestdir
    # stop template() fn from complaining about missing vardir config
    Puppet[:vardir] ||= ""
  end
end

RSpec.configure do |c|
  c.add_setting :modulepath, :default => '/etc/puppet/modules'
  c.add_setting :manifestdir, :default => nil

  # FIXME: decide if these are needed
  #c.add_setting :manifest, :default => nil
  #c.add_setting :template_dir, :default => nil
  #c.add_setting :config, :default => nil
end
