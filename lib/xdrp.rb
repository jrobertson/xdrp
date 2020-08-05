#!/usr/bin/env ruby

# file: xdrp.rb

# description: A basic macro recorder for GNU/Linux which uses 
#              program xinput to capture input events.

require 'rxfhelper'
require "xdo/mouse"
require "xdo/xwindow"
require "xdo/keyboard"
require 'xinput_wrapper'


MOUSE = 1
KEYBOARD = 2
KEYBOARD_MOUSE = 3

  
module Xdrp

  class Recorder

    attr_reader :xml
    
    # level:
    #    1 = mouse
    #    2 = keyboard
    #    3 = keyboard + mouse

    def initialize(levelx=KEYBOARD_MOUSE, level: levelx, debug: false)
      
      @xiw = XInputWrapper.new(verbose: true, debug: debug, callback: self)

      @mouse, @keyboard = false, false
      
      case level
      when 1
        @mouse = true
      when 2
        @keyboard = true
      when 3
        @mouse, @keyboard = true, true
      end
    end

    def on_keypress(key, keycode, modifier=nil)      

      if @debug then
        puts 'key: ' + key.inspect
        puts 'keycode: ' + keycode.inspect
        puts 'modifier: ' + modifier.inspect
      end

      stop() if modifier and modifier[0] == :alt and key == :z
      
      return unless @keyboard      

      add_sleep() if Time.now > (@t1 + 2)
      

      if @a.length >= 1 and @a[-1][0] == :type then

        if modifier.nil? or (modifier and modifier.empty?) then
          @a[-1][2] += key.to_s.sub('{space}', ' ')
        else
          
          if modifier.length < 2  then
            
            if modifier.first == :shift and (keycode.between?(10,21) \
                                             or keycode.between?(24,35) \
                                             or keycode.between?(38,48)) then
              
              char = if key.to_s =~ /[a-z]/ then
                key.to_s.upcase
              elsif key.to_s =~ /[0-9]/
                %w[) ! " £ $ % ^ & * ( ][key.to_s.to_i]
              else
                                
                lsym = %w(` - = [ ] ; ' # \ , . /)
                
                if lsym.include? key.to_s then

                  usym = %w(¬ _ + { } : @ ~ | < > ?)
                  lsym.zip(usym).to_h[key.to_s]

                end

              end
              
              @a[-1][2] += char
              
            else
              @a << [modifier.first, {key: key}] 
            end
          end
        end        

      else

        a = case key.to_s[/^\{(\w+)\}$/,1]
        when 'enter'
          [:enter]
        when 'tab'
          [:tab]
        else
          [:type, {}, key.to_s.sub(/\{space\}/, ' ')]
        end

        @a << a

      end

    end

    def on_mousedown(button, x, y)

      return unless @mouse
      
      puts "mouse %s button down at %s, %s" % [button, x, y] if @debug
      add_sleep() if Time.now > (@t1 + 2)
      @a << [:mouse, {click: button, x: x, y: y}]

    end

    def on_mouseup(button, x, y)
      
      return unless @mouse
      
      puts "mouse %s button up at %s, %s" % [button, x, y] if @debug
    end

    def on_mousemove(x, y)

      return unless @mouse
      
      puts 'mouse is moving at ' + x.to_s + ' y ' + y.to_s if @debug
      add_sleep() if Time.now > (@t1 + 2)
      @a << [:mousemove, {x: x, y: y}]

    end

    def on_mouse_scrolldown()

      return unless @mouse
      
      puts 'mouse is scrolling down' if @debug
      add_sleep() if Time.now > (@t1 + 2)
      @a << [:mousewheel, {scroll: 'down'}]

    end

    def on_mouse_scrollup()

      return unless @mouse
      
      puts 'mouse is scrolling up ' if @debug
      add_sleep() if Time.now > (@t1 + 2)
      @a << [:mousewheel, {scroll: 'up'}]

    end
    
    def save(filepath)
      File.write filepath, xml()
    end

    def start()
      
      @a = []
      Thread.new { @xiw.listen }
      puts 'recording ...'
      @t1 = Time.now
      
    end

    def stop()
      
      @xiw.stop = true
      @doc = Rexle.new(['xdrp', {}, '', *@a])
      puts 'recording stopped'
      
    end

    def xml()
      @doc.xml(pretty: true)
    end

    private

    def add_sleep()
      @a << [:sleep, {duration: (Time.now - @t1).round}]
      @t1 = Time.now
    end

  end

  class Player

    def initialize(src, debug: false)

      @debug = debug
      @doc = Rexle.new(RXFHelper.read(src).first)

    end

    def play()

      @doc.root.elements.each do |e|
        puts 'e: ' + e.xml.inspect if @debug
        method('xdo_' + e.name.to_s).call(e.text || e.attributes)
      end

    end

    private

    def xdo_enter(h={})
      XDo::Keyboard.return
    end

    def xdo_mouse(click: 'left', x: 0, y: 0)
      XDo::Mouse.click(x.to_i, y.to_i, 
                       Object.const_get('XDo::Mouse::' + click.upcase))
    end

    def xdo_mousemove(x: 0, y: 0)
      XDo::Mouse.move(x.to_i, y.to_i)
    end
                      
    def xdo_mousewheel(scroll: 'down')
      XDo::Mouse.wheel(Object.const_get('XDo::Mouse::' + scroll.upcase, 4))
    end                      

    def xdo_sleep(duration: 0)
      sleep duration.to_f
    end

    def xdo_tab(h={})
      XDo::Keyboard.tab
    end

    def xdo_type(s)
      XDo::Keyboard.simulate(s.gsub('{enter}', "\n"))
    end

  end

end
