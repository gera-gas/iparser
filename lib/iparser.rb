#--
# iparser.rb - Universal parser machine to generate your specific parsers.
#++
require 'iparser/version'

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
      @ignore  = []
      @ientry  = 0   # use to save compred index of this state.
      @ileave  = 0   # use to save compred index of this state.
      @entry   = []  # template chars for entry state.
      @leave   = []  # template chars for leave state.
      @branches = [] # indexes of any states to branch.
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

  
  #  Used for create parser machine.
  class Machine
    INITIAL_STATE = 'wait'

    attr_reader :parserstate

    # call-seq:
    #  Machine.new( )
    def initialize ( )
      @buffer = [] # буфер для символов входного потока
      @states = [] # массив с состояниями парсера, <ParserState> объекты
      @chain  = [] # цепочка работающих состояний
      #
      # Машина состояний для метода classify.
      #
      @matchstate = {
	:state => 0,
	:index => 0
      }
      @parserstate = ''
    end

    # Сбрасывает чувствительные переменные.
    def reset ( ) # :nodoc:
      @buffer = []
      @states.each do |s|
	s.ientry = 0
	s.ileave = 0
      end
    end
    
    # Return current state name.
    def current_state ( )
      return @chain.last.statename if @chain.size > 0
      return nil
    end

    # Initialize parser object,
    # should be called before call other methods.
    def prestart ( )
      reset( )
      @matchstate[:state] = 0
      @chain = [ @states[0], ]
    end

    # Display information about of each state of parser.
    def display ( )
      puts 'Parser states: ' + @states.size.to_s

      @states.each do |st|
	puts
	puts '** state: ' + st.statename
	puts 'branches: '
	st.branches.each do |br|
	  puts '  ' + @states[br].statename
	end
      end
    end
    
    # Обработка ввода для интерактивных режимов работы.
    def interactive_input ( ) # :nodoc:
      state = 0
      rv  = ""
      str = gets
      
      # Сразу нажата <Enter> => exit.
      return rv if str[0] == '\n'
      
      # Выполняем разбор посимвольно.
      str.each_char do |c|
	break if c == ?\n
	case state
	  #
	  # Сборка символов и проверка на наличие
	  # экранирующего символа, значит это ESC-символы.
	when 0
	  if c == '\\' then
	    state = 1
	  else
	    rv += c
	  end
	  #
	  # Анализ ESC символа.
	when 1
	  case c
	  when '0'
	    rv += "\0"
	  when 'n'
	    rv += "\n"
	  when 'r'
	    rv += "\r"
	  when '\\'
	    rv += "\\"
	  when 'a'
	    rv += "\a"
	  when 'b'
	    rv += "\b"
	  when 't'
	    rv += "\t"
	  when 'v'
	    rv += "\v"
	  when 'f'
	    rv += "\f"
	  else
	    puts "\nERROR: unrecognized esc-symbols.\n"
	    exit
	  end
	  state = 0
	end
      end
      return rv
    end
    
    # Обработка вывода для интерактивных режимов работы.
    def interactive_output( istr ) # :nodoc:
      str = []
      istr.bytes.each do |c|
	case c
	when 0
	  str << c.to_s + ":\\0"
	when 10
	  str << c.to_s + ":\\n"
	when 13
	  str << c.to_s + ":\\r"
	when 7
	  str << c.to_s + ":\\a"
	when 8
	  str << c.to_s + ":\\b"
	when 9
	  str << c.to_s + ":\\t"
	when 11
	  str << c.to_s + ":\\v"
	when 12
	  str << c.to_s + ":\\f"
	else
	  str << c.to_s + ":" + c.chr
	end
      end
      return str
    end
    
    # Run parser machine for check in interactive mode.
    def interactive_parser ( )
      puts 'Press <Enter> to exit...'
      
      # Цикл обработки ввода.
      loop do
	str = interactive_input( )
	break if str == ""
      
	# Цикл посимвольной классификаци.
	str.bytes.each do |c|
	  parse( c.chr )
	  puts 'parser: ' + @parserstate
	  puts 'symbol: ' + interactive_output( c.chr ).to_s
	  puts 'state:  ' + @chain.last.statename
	  puts
	end
      end
    end

    # call-seq:
    #  s = Parser::State.new('idle')
    #  p = Parser::Machine.new
    #  p << s
    #
    # Add any parser-state to current parser.
    def addstate ( ps )
      raise TypeError, ps.class.to_s + ': Incorrectly types for \'<<\' method of <Parser>.' unless
	ps.instance_of? State
      @states << ps
    end
    
    # call-seq:
    #   some_state1.branches << parser.state_index(some_state2).
    # Return index 
    def state_index ( state )
      raise TypeError, ps.class.to_s + ': Incorrectly types for \'state_index\' method of <Parser>.' unless
	state.instance_of? State
	
      @states.each_with_index do |st,i|
	return i if state == st
      end
      raise "State <#{state.statename}> is not exist in Parser."
    end

    # Сравнивает символы входного потока 
    # с символами из указанного шаблона.
    # В качестве шаблона выступают поля <entry> или <leave>
    # объектов типа <ParserState>.
    def cmp ( tmp, idx ) # :nodoc:

      # проверка на случай если шаблон не задан,
      # т.е. проинициализирован в [].
      if tmp.size > 0 then
	if idx < tmp.size then
	  case tmp[idx].class.to_s
	  when 'Regexp'
	    return true if @buffer.last =~ tmp[ idx ]
	  when 'String'
	    return true if @buffer.last == tmp[ idx ]
	  end
	end
      end
      return false
    end

    # Поиск в массиве указанного диапазона,
    # указанного в параметрах символа.
    #
    # >=0 : индекс совпавшего элемента.
    #  -1 : нет совпадений.
    def checkback ( tmp, len ) # :nodoc:
      if len > 0 then
	i = len
	len.times do
	  i = i - 1
	  return i if cmp( tmp, i )
	end
      end
      return -1
    end

    # Находит соответствие между символами входного потока
    # и возможными переходами.
    #
    # При совпадени возвращает индекс состояния
    # в массиве состояний, иначе:
    #
    # >0 : прыжок в новое состояние
    # -1 : возврат в предыдущее состояние 
    # -2 : еще идет проверка.
    # -3 : нет cовпадений (промах).
    def classify ( state ) # :nodoc:
      case @matchstate[:state]
	
      # Состояние еще не определено.
      # :state = 0
      when 0
	mcount = 0
	mindex = 0
	backtag = 0
	#
	# Проверка условия выхода из состояния.
	if cmp( state.leave, state.ileave ) then
	  state.ileave = state.ileave.next
	  #
	  # Возврат в предыдущее состояние.
	  if state.ileave >= state.leave.size then
	    return -1
	  end
	  backtag = 1
	else
	  #
	  # Нет совпадения, но если уже часть сравнений
	  # успешна, то возможно входной символ совпадает
	  # с предыдущими, уже совпавшими символами,
	  # т.е. как откат в режиме <wait>.
	  #
	  i = checkback( state.leave, state.ileave )

	  if i != -1 then
	    state.ileave = i.next
	    backtag = 1
	  else
	    state.ileave = 0
	    backtag = 0
	  end
	end
	#
	# Проверка возможных переходов для
	# указанного в параметрах состояния.
	state.branches.each do |b|
	  if cmp( @states[b].entry, @states[b].ientry ) then
	    mcount = mcount + 1
	    mindex = b
	    @states[b].ientry = @states[b].ientry.next
	    #
	    # состояние полностью пройдено.
	    if @states[ b ].ientry >= @states[ b ].entry.size then
	      return b
	    end
	  else
	    #
	    # Нет совпадения, но если уже часть сравнений
	    # успешна, то возможно входной символ совпадает
	    # с предыдущими, уже совпавшими символами,
	    # т.е. как откат в режиме <wait>.
	    i = checkback( @states[b].entry, @states[b].ientry )

	    if i != -1 then
	      mcount = mcount + 1
	      mindex = b
	      @states[b].ientry = i.next
	    else
	      @states[b].ientry = 0
	    end
	  end
	end
	#
	# Анализ количества совпадений.
	case mcount
	#
	# нет совпадений.
	when 0
	  return (-3 + backtag)
	#
	# однозначное совпадение, но весь массив шаблонов
	# еще не пройден.
	when 1
	  @matchstate[:state] = 1
	  @matchstate[:index] = mindex
	  return -2
	#
	# нет однозначного соответствия.
	else
	  return -2
	end
	
      # Состояние точно определено.
      # :state = 1
      when 1
	i = @matchstate[:index]
	if cmp( @states[ i ].entry, @states[ i ].ientry ) then
	  #
	  # Инкремент счетчика (индекса) вхождений.
	  @states[ i ].ientry = @states[ i ].ientry.next
	  #
	  # Массив шаблонов совпадает полностью.
	  # можно считать, что 100% совпадение.
	  if @states[ i ].ientry >= @states[ i ].entry.size then
	    @matchstate[:state] = 0
	    return i
	  end
	  return -2
	end
	#
	# Нет совпадения, но если уже часть сравнений
	# успешна, то возможно входной символ совпадает
	# с предыдущими, уже совпавшими символами,
	# т.е. как откат в режиме <wait>.
	idx = checkback( @states[i].entry, @states[i].ientry )

	if idx != -1 then
	  @states[i].ientry = idx.next
	  return -2
	end
	@states[i].ientry = 0
	@matchstate[:state] = 0
	return -3
      end # case @matchstate
    end

    # Main method, used for parse input stream.
    # Parse will be starting in unit with nil index (0).
    #
    # Return true if parsing process is successful, else return false.
    def parse ( c )
      @parserstate = INITIAL_STATE
      retval = true
      #
      # * Фиксированное состояние (определенное): -1.
      # * Не фиксированное состояние (неопределенное): -2.
      # * Переход (смена состояний): >0.
      # 
      @buffer << c

      # Проверка переходов в другие состояния.
      r = classify( @chain.last )

      # Переход (прыжок) в другое состояние.
      # <branch>:
      if r >= 0 then
	@chain << @states[r]
	if @chain.last.run_init( @buffer ) == nil then
	  reset( )
	  @parserstate = 'branch'
	else
	  @parserstate = 'error'
	  retval = false
	end
	
      # Возврат из текущего состояния.
      # <back>:
      elsif r == -1 then
	if @chain.last.run_fini( @buffer ) == nil then
	  #
	  # если это состояние не первое в цепочке
	  # тогда откатываемся назад.
	  if @chain.size > 1 then
	    @chain.delete_at( @chain.size - 1 )
	  end
	  reset( )
	  @parserstate = 'back'
	else
	  @parserstate = 'error'
	  retval = false
	end
	
      # Нет совпадений.
      # <miss>:
      elsif r == -3 then
	#
	# если в процессе состояния <wait>
	# мы попали в <miss>, то накопленный
	# буфер надо обработать.
	@buffer.each do |ch|
	  @parserstate = 'miss'
	  tag = true
	  if @chain.last.ignore.size > 0 then
	    tag = false if @chain.last.ignore.include?(ch)
	  end
	  if tag == true then
	    r = @chain.last.run_handler( ch )
	    #
	    # Анализ результата обработки состояния.
	    case r.class.to_s
	    #
	    # Fixnum - переход на любое состояние (индекс).
	    when 'Fixnum'
	      if( (r >= 0) && (r < @states.size) ) then
		@chain << @states[r]
		reset( )
		@parserstate = 'hardset'
	      else
		raise TypeError, "Method <#{@chain.last.statename}> return incorrectly index."
	      end
	    #
	    # nil - ничего не возвращает.
	    when 'NilClass'
	    #
	    # else - расценивается как ошибка обработки.
	    # обработка ложится на плечи разработчика.
	    else
	      @parserstate = 'error'
	      retval = false
	      break
	    end
	  end
	end
	@buffer = []
      end
      return retval
    end
    
    private :reset, :cmp, :checkback, :interactive_input, :interactive_output
  end # class Machine

end
