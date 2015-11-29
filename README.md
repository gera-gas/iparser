# Iparser

Universal parser machine to generate your specific parsers.
Used for simple and fast create your specific parsers.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'Iparser'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install iparser

## Usage

For example usage, present here very simple parser for automatically generate documentation from source code.

*source № 1*:
```ruby
require 'iparser'

#
# Create parser-machine object.
#
parser = Iparser::Machine.new

#
# Create startup state for this parser-machine.
#
ps_idle = Iparser::State.new('idle')

#
# Add branch indexes to 'comment-line' and 'comment-block' state.
#
ps_idle.branches << 1
ps_idle.branches << 2

#
# Create single line comment state for this parser-machine.
#
ps_cline = Iparser::State.new('comment-line')
ps_cline.entry << /\//
ps_cline.entry << /\//
ps_cline.entry << /\//
ps_cline.leave << /[\n\r]/

#
# Create multiline comment state for this parser-machine.
#
ps_cblock = Iparser::State.new('comment-block')
ps_cblock.entry << /\//
ps_cblock.entry << /\*/
ps_cblock.entry << /\*/
ps_cblock.leave << /\*/
ps_cblock.leave << /\//
ps_cblock.ignore << '*'

#
# Add all states to parser-machine.
#
parser.addstate ps_idle
parser.addstate ps_cline
parser.addstate ps_cblock

#
# Call parser startup method.
#
parser.prestart

#
# Call interactive mode for check state-machine.
#
parser.interactive_parser
```

Run this script and typing `'///'` for branch to 'comment-line' state. Then type `'\n'` or `'\r'` for leave this state.
**NOTE**: Type `'\\'` for input `'\'`. Check each state. Press `enter` (input empty string) to leave interactive mode.
After successfully check, add the following code to the beginning of the file:

*source № 2*:
```ruby
#
# Simple check startup arguments.
#
if( ARGV.size != 1 || !File.exist?(ARGV[0]) )
  puts
  puts "ERROR: unable to open file #{ARGV[0]}"
  puts
  exit
end
#
# Create output file.
#
$fout = File.new( 'index.html', 'w' )

#
# Create initializer method for parser-states.
#
def doc_init ( str )
  $fout.print "<p>"
end
#
# Create handler method for parser-states.
#
def doc_handler ( c )
  $fout.print c
end
#
# Create finalizer method for parser-states.
#
def doc_fini ( str )
  $fout.puts "</p>"
end
```
Method `doc_init` is state contructor.
Method `doc_handler` is state handler and call in `comment-line` or `comment-block` for each input char.
Method `doc_fini` is state destructor.

Handler may be return following data types: `Fixnum` - index to branch (>=0),
`NilClass` - hold current state (nil) and any data types for break parse (error, method `parse`
return `false`).

For `comment-block` state set ignore char - `*`, and handler don't called to this chars.

Add the following code instead `parser.interactive_parser`:

*source № 3*:
```ruby
$fout.puts "<html>"
$fout.puts "<body>"

File.open( ARGV[0], 'r' ).each do |line|
  line.each_char do |c|
    parser.parse(c)
  end
end

$fout.puts "</body>"
$fout.puts "</html>"
$fout.close
```

And add this code (*source № 4*) before `addstate` method call.

*source № 4*:
```ruby
#
# Add handlers for states.
#
ps_cline.init( method(:doc_init) )
ps_cline.handler( method(:doc_handler) )
ps_cline.fini( method(:doc_fini) )

ps_cblock.init( method(:doc_init) )
ps_cblock.handler( method(:doc_handler) )
ps_cblock.fini( method(:doc_fini) )
```

The result is a file with the following content.

*source № 5*:
```ruby
require 'iparser'

#
# Simple check startup arguments.
#
if( ARGV.size != 1 || !File.exist?(ARGV[0]) )
  puts
  puts "ERROR: unable to open file #{ARGV[0]}"
  puts
  exit
end
#
# Create output file.
#
$fout = File.new( 'index.html', 'w' )

#
# Create initializer method for parser-states.
#
def doc_init ( str )
  $fout.print "<p>"
end
#
# Create handler method for parser-states.
#
def doc_handler ( c )
  $fout.print c
end
#
# Create finalizer method for parser-states.
#
def doc_fini ( str )
  $fout.puts "</p>"
end

#
# Create parser-machine object.
#
parser = Iparser::Machine.new

#
# Create startup state for this parser-machine.
#
ps_idle = Iparser::State.new('idle')

#
# Add branch indexes to 'comment-line' and 'comment-block' state.
#
ps_idle.branches << 1
ps_idle.branches << 2

#
# Create single line comment state for this parser-machine.
#
ps_cline = Iparser::State.new('comment-line')
ps_cline.entry << /\//
ps_cline.entry << /\//
ps_cline.entry << /\//
ps_cline.leave << /[\n\r]/

#
# Create multiline comment state for this parser-machine.
#
ps_cblock = Iparser::State.new('comment-block')
ps_cblock.entry << /\//
ps_cblock.entry << /\*/
ps_cblock.entry << /\*/
ps_cblock.leave << /\*/
ps_cblock.leave << /\//
ps_cblock.ignore << '*'

#
# Add handlers for states.
#
ps_cline.init( method(:doc_init) )
ps_cline.handler( method(:doc_handler) )
ps_cline.fini( method(:doc_fini) )

ps_cblock.init( method(:doc_init) )
ps_cblock.handler( method(:doc_handler) )
ps_cblock.fini( method(:doc_fini) )

#
# Add all states to parser-machine.
#
parser.addstate ps_idle
parser.addstate ps_cline
parser.addstate ps_cblock

#
# Call parser startup method.
#
parser.prestart

#
# Call interactive mode for check state-machine.
#
$fout.puts "<html>"
$fout.puts "<body>"

File.open( ARGV[0], 'r' ).each do |line|
  line.each_char do |c|
    parser.parse(c)
  end
end

$fout.puts "</body>"
$fout.puts "</html>"
$fout.close
```

Now developing of the simple parser has been finished. You can create test file, for example 'test.c':

*source № 6*:
```
#include <stdlib.h>

///Test function - 1.
void test1 ( void )
{
}
/**
 * Test function - 2.
 */
void test2 ( void )
{
}
```

and do folow command in command line as:

    $ ruby <you parser script name>.rb test.c

After work, we should see a file named 'index.html'.

###### Своих не бросаем!
------------------------

Для примера использования данного gem, напишем простой парсер файла исходного кода
для автоматической генерации документации, отдаленно напоминающего doxygen.
Создадим ruby скрипт c именем 'parser_example.rb' и наполним его содержимым из *source № 1*.

Далее запустим скрипт на выполнение:

    $ ruby parser_example.rb

Теперь в интерактивном режиме проверим корректность описанных нами состояний: `comment-line` и `comment-block`.
Для чего введем строку символов `///` и увидим что наш парсер вывел `branch to <comment-line>`, это говорит
о том, что парсер перешол в состояние для обработки однострочных комментариев, т.е. в состояние `comment-line`.
Теперь введем `\n` или `\r` и увидим что парсер покинул состояние `comment-line` и вернулся в состояние `idle`.
Аналогично проведем проверку для всех оставшихся состояний. Для выхода из интерактивного режима просто введите
`Enter`, т.е. пустую строку.

**NOTE**: для ввода символа `'\'` необходимо набрать `'\\'`.

Если все переходы работают как мы и ожидали, то
можно перейти к написанию обработчиков наших состояний. Для этого допишем в наш скрипт код из *source № 2*
в начало файла и вместо строки `parser.interactive_parser` добавим код из *source № 3* и *source № 4*.
В результате должен получится код как на *source № 5*.

Метод `doc_init` будет вызываться при входе в состояние, т.е. является конструктором состояния.
Метод `doc_handler` будет вызываться каждый раз, до тех пор пока парсер находится в состоянии `comment-line` или `comment-block`.
Метод `doc_fini` будет вызываться при выходе из состояния, т.е. является деструктором состояния.

Обработчик состояния должен возвращать следующие типы данных:  `Fixnum` - индекс состояния на которое надо перейти (>=0),
`NilClass` - оставаться в текущем состоянии (nil) и остальные типы данных которые будут расценены как ошибка
обработки и метод `parse` вернет `false` (error). Во всех остальных случаях `parse` возвращает `true`.

Дополнительно для состояния `comment-block` мы указали символы, которые надо игнорировать,
а именно `'*'` и `doc_handler` не будет вызываться при наличия данного символа во входном потоке.

И наконец создадим тестовый файл с именем 'test.c' и наполним его содержимым из *source № 6*.
Наш простой парсер готов. Теперь запустим его набрав следующую команду:

    $ ruby parser_example.rb test.c

По окончанию работы мы должны увидеть файл с именем 'index.html'.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/parser. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

