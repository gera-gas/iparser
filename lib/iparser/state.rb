module Iparser
  #  Used for describe single state
  #  of parser machine.
  class State
    attr_reader :statename
    attr_accessor :branches, :entry, :leave, :ientry, :ileave, :ignore

    # call-seq:
    #  State.new(String)
    def initialize(sname)
      unless sname.instance_of? String
        raise TypeError, 'Incorrectly types for <ParserState> constructor.'
      end

      @statename = sname
      @ignore    = []
      @ientry    = 0     # use to save compred index of this state.
      @ileave    = 0     # use to save compred index of this state.
      @entry     = []    # template chars for entry state.
      @leave     = []    # template chars for leave state.
      @branches  = []    # indexes of any states to branch.
    end

    # call-seq:
    #   init(method(:some_init_method))
    #
    # Set initializer method for current state.
    def init(method)
      raise TypeError, error_message(method, __method__) unless method.instance_of? Method
      @init = method
    end

    # call-seq:
    #   fini(method(:some_fini_method))
    #
    # Set finalizer method for current state.
    def fini(method)
      raise TypeError, error_message(method, __method__) unless method.instance_of? Method
      @fini = method
    end

    def run_init( *args ) # :nodoc:
      return @init.call( *args ) if @init
    end

    def run_fini( *args ) # :nodoc:
      return @fini.call( *args ) if @fini
    end

    # call-seq:
    #   handler( method(:some_handler_method) )
    #
    # Set handler method for current state.
    def handler(handler)
      raise TypeError, error_message(handler, __method__) unless handler.instance_of? Method
      @handler = handler
    end

    def run_handler(*args) # :nodoc:
      return @handler.call(*args) if @handler
    end

  private
    def error_message(object, method)
      "#{object.class}: Incorrectly types for <#{method}> method of <ParserState>."
    end
  end
end
