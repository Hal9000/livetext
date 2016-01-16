

def parse(line)
  chars = line.scan(/./).each

  arglist = []
  arg = ""
  c = chars.next
  loop do
    case c
      when '"' # grab a quoted string
        loop do 
          arg << chars.next
        end
      when '\\'
    end
  end
end

STDIN.each do |line|
  parse(line)
end
