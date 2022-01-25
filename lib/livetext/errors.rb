
# More later?

def make_exception(sym, str, target_class = Object)
  return if target_class.constants.include?(sym)
  klass = sym   # :"#{sym}_Class"
  target_class.const_set(klass, StandardError.dup)
  define_method(sym) do |*args|
    args = [] unless args.first
    msg = str.dup
    args.each.with_index {|arg, i| msg.sub!("%#{i+1}", arg.to_s) }
    target_class.class_eval(klass.to_s).new(msg)
  end
end

make_exception(:EndWithoutOpening, "Error: found .end with no opening command")
make_exception(:UnknownMethod,     "Error: name '%1' is unknown")

