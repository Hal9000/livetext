file = ARGV.first

meths = `grep def\  #{file}`

puts <<-EOF
.mixin docsen

.context #{file}

.para off
.backtrace

.set nodoc="&nbsp;&nbsp;<b>Not documented yet.</b><br><br>"

EOF

meths.each_line do |line|
  line.chomp!
  line.sub!(/ *def /, "")
  puts <<-EOF
.command .#{line}
  $nodoc
.end

EOF
end


puts "\n.finalize\n "

