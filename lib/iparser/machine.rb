module Iparser
  #  Used for create parser machine.
  class Machine
    INITIAL_STATE = 'wait'

    attr_reader :parserstate

    def initialize
      @buffer = [] # буфер для символов входного потока
      @states = [] # массив с состояниями парсера, <ParserState> объекты
      @chain  = [] # цепочка работающих состояний

      # Машина состояний для метода classify.
      @matchstate = {
        state: 0,
        index: 0
      }
      @parserstate = ''
    end

    # Сбрасывает чувствительные переменные.
    def reset # :nodoc:
      @buffer = []
      @states.each do |state|
        state.ientry = 0
        state.ileave = 0
      end
    end

    # Initialize parser object,
    # should be called before call other methods.
    def prestart
      reset
      @matchstate[:state] = 0
      @chain = [@states[0]]
    end

    # Display information about of each state of parser.
    def display
      puts "Parser states: #{@states.size}"

      @states.each do |state|
        puts "\n" + '*' * 80
        puts "state:\n\t#{state.statename}"
        puts 'branches: '
        state.branches.each do |branch|
          puts "\t#{@states[branch].statename}"
        end
      end
    end

    # Обработка ввода для интерактивных режимов работы.
    def interactive_input # :nodoc:
      state = 0
      rv  = ''
      str = gets

      # Сразу нажата <Enter> => exit.
      return rv if str[0] == '\n'

      # Выполняем разбор посимвольно.
      str.each_char do |char|
        break if char == ?\n
        case state
          #
          # Сборка символов и проверка на наличие
          # экранирующего символа, значит это ESC-символы.
        when 0
          if char == '\\'
            state = 1
          else
            rv += char
          end
          #
          # Анализ ESC символа.
        when 1
          case char
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
      rv
    end

    # Обработка вывода для интерактивных режимов работы.
    def interactive_output(istr) # :nodoc:
      istr.bytes.map do |char|
        case char
        when 0
          "#{char}:\\0"
        when 10
          "#{char}:\\n"
        when 13
          "#{char}:\\r"
        when 7
          "#{char}:\\a"
        when 8
          "#{char}:\\b"
        when 9
          "#{char}:\\t"
        when 11
          "#{char}:\\v"
        when 12
          "#{char}:\\f"
        else
          "#{char}:#{char.chr}"
        end
      end
    end

    # Run parser machine for check in interactive mode.
    def interactive_parser
      puts 'Press <Enter> to exit...'

      # Цикл обработки ввода.
      loop do
        string = interactive_input
        break if string.empty?

        # Цикл посимвольной классификаци.
        string.bytes.each do |char|
          parse(char.chr)
          puts "parser: #{@parserstate}"
          puts "symbol: #{interactive_output(char.chr)}"
          puts "buffer: #{@buffer}"
          puts "state:  #{@chain.last.statename}\n"
        end
      end
    end

    # call-seq:
    #  s = Parser::State.new('idle')
    #  p = Parser::Machine.new
    #  p << s
    #
    # Add any parser-state to current parser.
    def addstate(ps)
      raise TypeError, "#{ps.class}: Incorrectly types for '<<' method of <Parser>." unless ps.instance_of? State
      @states << ps
    end

    # Сравнивает символы входного потока
    # с символами из указанного шаблона.
    # В качестве шаблона выступают поля <entry> или <leave>
    # объектов типа <ParserState>.
    def cmp(tmp, idx) # :nodoc:
      # проверка на случай если шаблон не задан,
      # т.е. проинициализирован в [].
      if tmp.size > 0
        if idx < tmp.size
          return true if @buffer.last =~ tmp[idx]
        end
      end
    end

    # Поиск в массиве указанного диапазона,
    # указанного в параметрах символа.
    #
    # >=0 : индекс совпавшего элемента.
    #  -1 : нет совпадений.
    def checkback(tmp, length) # :nodoc:
      return -1 if length <= 0

      (length..0).times do |i|
        return i if cmp(tmp, i)
      end
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
    def classify(state) # :nodoc:
      case @matchstate[:state]
        # Состояние еще не определено.
        # :state = 0
      when 0
        mcount = 0
        mindex = 0
        backtag = 0

        # Проверка условия выхода из состояния.
        if cmp(state.leave, state.ileave)
          state.ileave = state.ileave.next

          # Возврат в предыдущее состояние.
          if state.ileave >= state.leave.size
            return -1
          end
          backtag = 1
        else
          # Нет совпадения, но если уже часть сравнений
          # успешна, то возможно входной символ совпадает
          # с предыдущими, уже совпавшими символами,
          # т.е. как откат в режиме <wait>.
          i = checkback(state.leave, state.ileave)

          if i != -1
            state.ileave = i.next
            backtag = 1
          else
            state.ileave = 0
            backtag = 0
          end
        end

        # Проверка возможных переходов для
        # указанного в параметрах состояния.
        state.branches.each do |branch|
          if cmp(@states[branch].entry, @states[branch].ientry)
            mcount = mcount + 1
            mindex = branch
            @states[branch].ientry = @states[branch].ientry.next

            # состояние полностью пройдено.
            if @states[ branch ].ientry >= @states[ branch ].entry.size
              return branch
            end
          else
            # Нет совпадения, но если уже часть сравнений
            # успешна, то возможно входной символ совпадает
            # с предыдущими, уже совпавшими символами,
            # т.е. как откат в режиме <wait>.
            checkback_value = checkback(@states[branch].entry, @states[branch].ientry)

            if checkback_value != -1
              mcount = mcount + 1
              mindex = branch
              @states[branch].ientry = checkback_value.next
            else
              @states[branch].ientry = 0
            end
          end
        end

        # Анализ количества совпадений.
        case mcount
          # нет совпадений.
        when 0
          return (-3 + backtag)
          # однозначное совпадение, но весь массив шаблонов
          # еще не пройден.
        when 1
          @matchstate[:state] = 1
          @matchstate[:index] = mindex
          return -2
          # нет однозначного соответствия.
        else
          return -2
        end
        # Состояние точно определено.
        # :state = 1
      when 1
        i = @matchstate[:index]
        if cmp(@states[i].entry, @states[i].ientry)
          # Инкремент счетчика (индекса) вхождений.
          @states[i].ientry = @states[i].ientry.next

          # Массив шаблонов совпадает полностью.
          # можно считать, что 100% совпадение.
          if @states[i].ientry >= @states[i].entry.size
            @matchstate[:state] = 0
            return i
          end
          return -2
        end

        # Нет совпадения, но если уже часть сравнений
        # успешна, то возможно входной символ совпадает
        # с предыдущими, уже совпавшими символами,
        # т.е. как откат в режиме <wait>.
        idx = checkback(@states[i].entry, @states[i].ientry)

        if idx != -1
          @states[i].ientry = idx.next
          return -2
        end
        @states[i].ientry = 0
        @matchstate[:state] = 0
        return -3
      end
    end

    # Main method, used for parse input stream.
    # Parse will be starting in unit with nil index (0).
    #
    # Return true if parsing process is successful, else return false.
    def parse(c)
      @parserstate = INITIAL_STATE
      retval = true

      # * Фиксированное состояние (определенное): -1.
      # * Не фиксированное состояние (неопределенное): -2.
      # * Переход (смена состояний): >0.
      @buffer << c

      # Проверка переходов в другие состояния.
      r = classify(@chain.last)

      # Переход (прыжок) в другое состояние.
      # <branch>:
      if r >= 0
        @chain << @states[r]
        @chain.last.run_init @buffer
        reset
        @parserstate = 'branch'

        # Возврат из текущего состояния.
        # <back>:
      elsif r == -1
        @chain.last.run_fini @buffer

        # если это состояние не первое в цепочке
        # тогда откатываемся назад.
        if @chain.size > 1
          @chain.delete_at(@chain.size - 1)
        end
        reset
        @parserstate = 'back'

        # Нет совпадений.
        # <miss>:
      elsif r == -3
        # если в процессе состояния <wait>
        # мы попали в <miss>, то накопленный
        # буфер надо обработать.
        @buffer.each do |ch|
          @parserstate = 'miss'
          tag = true
          if @chain.last.ignore.size > 0
            tag = false if @chain.last.ignore.include?(ch)
          end
          if tag == true
            r = @chain.last.run_handler(ch)

            # Анализ результата обработки состояния.
            case r
              # Fixnum - переход на любое состояние (индекс).
            when Fixnum
              if (r >= 0) && (r < @states.size)
                @chain << @states[r]
                reset
                @parserstate = 'hardset'
              else
                raise TypeError, "Method <#{@chain.last.statename}> return incorrectly index."
              end

              # nil - ничего не возвращает.
            when NilClass
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
      retval
    end

    private :reset, :cmp, :checkback, :interactive_input, :interactive_output
  end
end
