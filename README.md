# Iparser

Universal parser machine to generate your specific parsers (Parser engine).
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
Create file 'parser_example.rb' and copy the contents from the file *source № 1*.

*source № 1*:
```ruby
require 'iparser'

# Create parser-machine object.
parser = Iparser::Machine.new
# Create startup state for this parser-machine.
ps_idle = Iparser::State.new('idle')
# Create single line comment state for this parser-machine.
ps_cline = Iparser::State.new('comment-line')
# Create multiline comment state for this parser-machine.
ps_cblock = Iparser::State.new('comment-block')

# Add all states to parser-machine.
parser.addstate ps_idle
parser.addstate ps_cline
parser.addstate ps_cblock

# Add branch indexes to 'comment-line' and 'comment-block' state.
# From 'idle' we can branch to 'comment-line' or 'comment-block' states.
ps_idle.branches << parser.state_index( ps_cline )
ps_idle.branches << parser.state_index( ps_cblock )

# Describe 'comment-line' state.
# Set template for entry this state (String or Regexp).
ps_cline.entry << '/'
ps_cline.entry << '/'
ps_cline.entry << '/'
# Set template for leave this state (String or Regexp).
ps_cline.leave << /[\n\r]/

# Describe 'comment-block' state.
# Set template for entry this state (String or Regexp).
ps_cblock.entry << '/'
ps_cblock.entry << '*'
ps_cblock.entry << '*'
# Set template for leave this state (String or Regexp).
ps_cblock.leave << '*'
ps_cblock.leave << '/'
# Set template for ignore this state (String format only).
ps_cblock.ignore[:handler] << '*'

# Call parser startup method.
parser.prestart
# Call interactive mode for check state-machine.
parser.interactive_parser
```

Run this script `ruby parser_example.rb` and typing `'///'` for branch to 'comment-line' state.
Then type `'\n'` or `'\r'` for leave this state.
Press `enter` (input empty string) to leave interactive mode.
Check each state.

**NOTE**: Type `'\\'` for input `'\'`.

Each state has the following templates:
* `entry`  - used for set condition (template) to entry state.
* `leave`  - used for set condition (template) to leave state (return to previous state).
* `ignore` - used for set symbols to ignoring.
 
After successfully check, you can add handler to each state.
Each state has the following handlers:
* `init` - is state contructor (called when entry to state).
* `fini` - is state destructor (called when leave state).
* `handler` - is state handler (called every time, is still in state).

Each handler can return the following values: __nil__ - nothing is done (method `.parse` return `true`)
and __any__ values for break parsing (method `.parse` return `false`). For break parsing process you
should check return value of `.parse` method. For example:
```ruby
parser = Iparser::Machine.new
'123asd'.each_char do |c|
  exit if !parser.parse(c)
end
```
Also each state have a `branches` field. Use the `branches` to add the index state,
which is a possible jump.

We create the following handlers:

* Method `doc_init` is state destructor.
* Method `doc_handler` is state handler and call in `comment-line` or `comment-block` for each input char.
* Method `doc_fini` is state destructor.

For `comment-block` state set ignore char - `*`, and handler don't called to this chars.
If you want set ignore chars for all handlers, using `.ignore[:all]`.
The result is a file with the following content of 'parser_example.rb':

Constructors and destructors handlers will be getting array chars with own templates.
For example `doc_init` getting follow array chars: `['/', '/', '/']`

*source № 2*:
```ruby
require 'iparser'

# Simple check startup arguments.
if( ARGV.size != 1 || !File.exist?(ARGV[0]) )
  puts
  puts "ERROR: unable to open file #{ARGV[0]}"
  puts
  exit
end

# Create output file.
$fout = File.new( 'index.html', 'w' )

# Create initializer method for parser-states.
def doc_init ( str )
  $fout.print "<p>"; return nil
end
# Create handler method for parser-states.
def doc_handler ( c )
  $fout.print c; return nil
end
# Create finalizer method for parser-states.
def doc_fini ( str )
  $fout.puts "</p>"; return nil
end

# Create parser-machine object.
parser = Iparser::Machine.new
# Create startup state for this parser-machine.
ps_idle = Iparser::State.new('idle')
# Create single line comment state for this parser-machine.
ps_cline = Iparser::State.new('comment-line')
# Create multiline comment state for this parser-machine.
ps_cblock = Iparser::State.new('comment-block')

# Add all states to parser-machine.
parser.addstate ps_idle
parser.addstate ps_cline
parser.addstate ps_cblock

# Add branch indexes to 'comment-line' and 'comment-block' state.
# From 'idle' we can branch to 'comment-line' or 'comment-block' states.
ps_idle.branches << parser.state_index( ps_cline )
ps_idle.branches << parser.state_index( ps_cblock )

# Describe 'comment-line' state.
# Set template for entry this state (String or Regexp).
ps_cline.entry << '/'
ps_cline.entry << '/'
ps_cline.entry << '/'
# Set template for leave this state (String or Regexp).
ps_cline.leave << /[\n\r]/
# Add handler to 'commaent-line' state.
ps_cline.init( method(:doc_init) )
ps_cline.handler( method(:doc_handler) )
ps_cline.fini( method(:doc_fini) )

# Describe 'comment-block' state.
# Set template for entry this state (String or Regexp).
ps_cblock.entry << '/'
ps_cblock.entry << '*'
ps_cblock.entry << '*'
# Set template for leave this state (String or Regexp).
ps_cblock.leave << '*'
ps_cblock.leave << '/'
# Set template for ignore this state (String format only).
ps_cblock.ignore[:handler] << '*'
# Add handler to 'commaent-block' state.
ps_cblock.init( method(:doc_init) )
ps_cblock.handler( method(:doc_handler) )
ps_cblock.fini( method(:doc_fini) )

# Call parser startup method.
parser.prestart

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

*source № 3*:
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

and execute folow command in command line as:

    $ ruby parser_example.rb test.c

After work, we should see a file named 'index.html'.

###### Своих не бросаем!
------------------------

Русскоязычное описание находится по ссылке: <http://habrahabr.ru/post/271969>

## Patch

Details information for each patch.

##### 2.0.0
* Clean analyse of handler return value, now all handlers (init,fini,handler) can return __nil__ or __any__ value.

##### 1.1.7
* `ignore` templates enabled devided on two group: `.ignore[:all]` - for all handlers, and `.ignore[:handler]` - for handler only.
* Refactoring code
* Corrected README example sources.

##### 1.1.6
* Fixed bug in analyse `leave` template (incorrectly handling, if `entry` and `leave` is begin with identical symbol).
* Now `ignore` template enabled for all handlers (init, fini, handler).

##### 1.1.5
* Add method `.current_state` for return name (String) of current state in parser-machine.

##### 1.1.4
* Add method `.state_index` for return index of parser-state.
* Add analyse result of any handler (init, fini, handler).
* Now `entry` and `leave` templates you can set a string or regular expression.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/parser. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

