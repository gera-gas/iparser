module Iparser
  #  Used for describe single state
  #  of parser machine.
  class State

    attr_reader :statename
    attr_accessor :branches, :entry, :leave, :ientry, :ileave, :ignore
  
    # call-seq:
    #  State.new( String )
    def initialize ( sname )
      unless sname.instance_of? String
        raise TypeError, 'Incorrectly types for <Parser-State> constructor.'
      end

      @statename = sname
      @init    = nil  # method called after entry (state constructor).
      @fini    = nil  # method called after leave (state destructor).
      @handler = nil  # state machine for handler current state.
      @ignore  = { :all => [], :handler => [] }
      @ientry  = 0    # use to save compred index of this state.
      @ileave  = 0    # use to save compred index of this state.
      @entry   = []   # template chars for entry state.
      @leave   = []   # template chars for leave state.
      @branches = []  # indexes of any states to branch.
    end

    # call-seq:
    #   init( method(:some_init_method) )
    #
    # Set initializer method for current state.
    def init ( method )
      raise TypeError, error_message(method, __method__) unless method.instance_of? Method
      @init = method
    end

    # call-seq:
    #   fini( method(:some_fini_method) )
    #
    # Set finalizer method for current state.
    def fini ( method )
      raise TypeError, error_message(method, __method__) unless method.instance_of? Method
      @fini = method
    end

    def run_init( *args ) # :nodoc:
      return @init.call( *args ) if @init != nil
      return nil
    end

    def run_fini( *args ) # :nodoc:
      return @fini.call( *args ) if @fini != nil
      return nil
    end

    # call-seq:
    #   handler( method(:some_handler_method) )
    #
    # Set handler method for current state.
    def handler ( method )
      raise TypeError,  error_message(method, __method__) unless method.instance_of? Method
      @handler = method
    end

    def run_handler( *args ) # :nodoc:
      return @handler.call( *args ) if @handler != nil
      return nil
    end
    
  private
    def error_message(object, method)
      "#{object.class}: Incorrectly types for <#{method}> method of <Parser-State>."
    end
  end # class State

end
