# A collection of micro-libraries, each intended to encapsulate
# a common task in Ruby
module Dryer
  # Create a new module to include and define an initializer for DI
  # - accessors will be private
  #
  # @example
  #   class Controller
  #     include Dryer::Constructor(:request, :response)
  #   end
  #
  # @param [Array<Symbol|String>] accessors
  #   The names of the accessor methods that will be added when included
  #
  # @return [Dryer::Constructor]
  #
  # @api public
  def self.Constructor(accessors)
    ::Dryer::Constructor.new(accessors)
  end

  # A simple dependency injection library for Plain Old Ruby Objects
  class Constructor < Module
    # Create a new module to include and define an initializer for DI
    # - accessors will be public
    #
    # @example
    #   class Controller
    #     include Dryer::Constructor::Public(:request, :response)
    #   end
    #
    # @param [Array<Symbol|String>] accessors
    #   The names of the accessor methods that will be added when included
    #
    # @return [Dryer::Constructor]
    #
    # @api public
    def self.Public(accessors)
      ::Dryer::Constructor.new(accessors, visibility: :public)
    end

    # Create a new module to include and define an initializer for DI
    # - accessors will be protected
    #
    # @example
    #   class Controller
    #     include Dryer::Constructor::Protected(:request, :response)
    #   end
    #
    # @param [Array<Symbol|String>] accessors
    #   The names of the accessor methods that will be added when included
    #
    # @return [Dryer::Constructor]
    #
    # @api public
    def self.Protected(accessors)
      ::Dryer::Constructor.new(accessors, visibility: :protected)
    end

    # Initialize an Equalizer with the given keys
    #
    # Create a new constructor module for inclusion
    #
    # @param [Array<Symbol|String>] accessors
    #   The names of the accessor methods that will be added when included
    # @param [Symbol|String] visibility
    #   The visibility of the accessor methods added on inclusion
    #
    # @return [Dryer::Constructor]
    #
    # @api private
    def initialize(accessors, visibility: :private)
      define_included(accessors, visibility)
      define_initializer(accessors)
      freeze
    end

    private

    # @api private
    def define_included(accessors, visibility)
      define_singleton_method(:included) do |descendant|
        keys = accessors.keys
        descendant.__send__(:attr_reader, *keys)
        descendant.__send__(visibility, *keys)
      end
    end

    # @api private
    def define_initializer(accessors)
      define_method(:initialize) do |args = {}, &_block|
        combined = accessors.merge(args)
        combined.each do |key, value|
          instance_variable_set("@#{key}", value)
        end
      end
    end
  end
end
