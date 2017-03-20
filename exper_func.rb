Funcs = %w[this b bc]

def this(text)
end

def b(text)
end

def bc(text)
end

def get_call(e)
  name = ""
  delim = nil
  if e.peek =~ /[A-Za-z]/
  puts "GOT EHRE"
    loop do
      name << e.next
      if [" ", ":", "("].include? e.peek
        delim = e.next
        return name, delim
      end
    end
  else
    puts "Warning: No function after $$"
  end
end


def subfunc(line)
  e = line.each_char
  loop do 
    if e.peek == "$"
      e.next
      if e.peek == "$"
        e.next
        name, delim = get_call(e)
        puts "name = #{name.inspect}  delim = #{delim.inspect}"
      end
    else
      puts e.next.inspect
    end
  end
end

line = "This is a line that calls $$this(some function) and that's about it"

subfunc(line)
