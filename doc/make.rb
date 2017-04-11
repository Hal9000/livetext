file = ARGV.first

meths = `grep def\  #{file}`

puts <<-EOF
.context #{file}
.para off
.hacktrace

.set nodoc="&nbsp;&nbsp;<b>Not documented yet.</b><br><br>"
EOF

meths.each_line do |line|
  line.chomp!
  line.sub!(/  def /, "")
  puts <<-EOF
.command .#{line}
  $nodoc
.end

EOF
end



