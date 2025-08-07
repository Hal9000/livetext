require 'minitest/autorun'

require_relative '../../lib/livetext'

class TestingLivetextVariableManager < Minitest::Test
  def setup
    @live = Livetext.new
  end

  def test_variable_manager_initialization
    # Test that VariableManager is properly initialized
    assert(@live.variables, "VariableManager should be initialized")
    assert_instance_of(Livetext::VariableManager, @live.variables)
  end

  def test_default_variables
    # Test that default variables are set
    assert_equal(`whoami`.chomp, @live.variables.get(:User))
    assert_equal(Livetext::VERSION, @live.variables.get(:Version))
    assert_equal(`hostname`.chomp, @live.variables.get(:Hostname))
    assert_equal(RUBY_PLATFORM, @live.variables.get(:Platform))
    assert_equal(RUBY_VERSION, @live.variables.get(:RubyVersion))
    assert_equal(Livetext::VERSION, @live.variables.get(:LivetextVersion))
  end

  def test_date_time_variables
    # Test that date/time variables are set
    now = Time.now
    assert_equal(now.year.to_s, @live.variables.get(:Year))
    assert_equal(now.mon.to_s, @live.variables.get(:Month))
    assert_equal(now.day.to_s, @live.variables.get(:Day))
    assert_equal(now.hour.to_s, @live.variables.get(:Hour))
    assert_equal(now.min.to_s, @live.variables.get(:Minute))
    assert_equal(now.sec.to_s, @live.variables.get(:Second))
    assert_equal(now.wday.to_s, @live.variables.get(:Weekday))
    assert_equal(now.strftime("%U"), @live.variables.get(:Week))
  end

  def test_set_and_get_variables
    # Test setting and getting custom variables
    @live.variables.set(:test_var, "test_value")
    assert_equal("test_value", @live.variables.get(:test_var))
  end

  def test_set_multiple_variables
    # Test setting multiple variables at once
    pairs = { var1: "value1", var2: "value2" }
    @live.variables.set_multiple(pairs)
    assert_equal("value1", @live.variables.get(:var1))
    assert_equal("value2", @live.variables.get(:var2))
  end

  def test_variable_exists
    # Test checking if variables exist
    @live.variables.set(:exists_test, "value")
    assert(@live.variables.exists?(:exists_test))
    refute(@live.variables.exists?(:nonexistent))
  end

  def test_bracket_access
    # Test bracket notation access
    @live.variables.set(:bracket_test, "bracket_value")
    assert_equal("bracket_value", @live.variables[:bracket_test])
  end

  def test_backward_compatibility
    # Test that the old vars interface still works
    assert(@live.vars, "vars method should still work")
    assert_equal(`whoami`.chomp, @live.vars.get(:User))
  end
end
