# p __FILE__


# More later?

def make_exception(sym, str, target_class = Object)
  return if target_class.constants.include?(sym)
  klass = sym   # :"#{sym}_Class"
  target_class.const_set(klass, StandardError.dup)
  define_method(sym) do |*args|
    args = [] unless args.first
    msg = str.dup
    args.each.with_index {|arg, i| msg.sub!("%#{i+1}", arg) }
    target_class.class_eval(klass.to_s).new(msg)
  end
end

