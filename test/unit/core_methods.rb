require 'minitest/autorun'
require_relative '../../lib/livetext'

class TestingLivetextCoreMethods < Minitest::Test
  def setup
    @live = Livetext.new
  end

  def test_customize_class_method
    # Test the class-level customize method
    obj = Livetext.customize(
      mix: [], 
      call: ['.nopara'], 
      vars: { 'test_var' => 'test_value' }
    )
    
    assert_instance_of(Livetext, obj)
    # The customize method should set up the instance with mixins, commands, and vars
  end

  def test_customize_instance_method
    # Test the instance-level customize method
    result = @live.customize(
      mix: [],
      call: ['.nopara'],
      vars: { 'test_var' => 'test_value' }
    )
    
    assert_equal(@live, result) # Should return self
  end

  def test_customize_with_plugin
    # Test customize with a real plugin
    obj = Livetext.customize(
      mix: ['tutorial'],
      call: [],
      vars: {}
    )
    
    assert_instance_of(Livetext, obj)
    # Should have loaded the tutorial plugin
    assert_includes(obj.methods, :title)
  end

  def test_customize_with_commands
    # Test customize with dot commands
    obj = Livetext.customize(
      mix: [],
      call: ['.set VAR="test_value"'],
      vars: {}
    )
    
    assert_instance_of(Livetext, obj)
    # Process some text to see if the variable was set
    body, vars = obj.process(text: "Variable: $VAR")
    assert_includes(body, "Variable: test_value")
  end

  def test_customize_with_variables
    # Test customize with variables
    obj = Livetext.customize(
      mix: [],
      call: [],
      vars: { 'name' => 'World', 'title' => 'Test' }
    )
    
    assert_instance_of(Livetext, obj)
    # Process some text to see if variables were set
    body, vars = obj.process(text: "Hello $name\n.h1 $title")
    assert_includes(body, "Hello World")
    assert_includes(body, "Test")
  end

  def test_customize_comprehensive
    # Test all features together
    obj = Livetext.customize(
      mix: ['tutorial'],
      call: ['.set PLUGIN_VAR="plugin_value"'],
      vars: { 'custom_var' => 'custom_value' }
    )
    
    assert_instance_of(Livetext, obj)
    
    # Test that plugin was loaded
    assert_includes(obj.methods, :title)
    
    # Test that variables were set
    body, vars = obj.process(text: "Plugin: $PLUGIN_VAR\nCustom: $custom_var")
    assert_includes(body, "Plugin: plugin_value")
    assert_includes(body, "Custom: custom_value")
  end

  def test_customize_error_handling
    # Test customize with invalid plugin
    assert_raises(FileNotFound) do
      Livetext.customize(mix: ['nonexistent_plugin'])
    end
  end

  def test_customize_empty_parameters
    # Test customize with empty parameters
    obj = Livetext.customize()
    assert_instance_of(Livetext, obj)
    
    # Should still work for basic processing
    body, vars = obj.process(text: "Hello world")
    assert_includes(body, "Hello world")
  end

  def test_customize_string_vs_array
    # Test that string parameters are converted to arrays
    obj = Livetext.customize(
      mix: 'tutorial',
      call: '.nopara',
      vars: { 'test' => 'value' }
    )
    
    assert_instance_of(Livetext, obj)
    assert_includes(obj.methods, :title)
  end

  def test_customize_variables_accessible
    # Test that variables passed to customize are actually accessible afterward
    obj = Livetext.customize(
      mix: [],
      call: [],
      vars: { 'name' => 'World', 'title' => 'Test Title', 'count' => '42' }
    )
    
    assert_instance_of(Livetext, obj)
    
    # Test that variables are accessible via vars.to_h
    vars_hash = obj.vars.to_h
    assert_equal('World', vars_hash[:name])
    assert_equal('Test Title', vars_hash[:title])
    assert_equal('42', vars_hash[:count])
    
    # Test that variables are accessible via variables.to_h
    variables_hash = obj.variables.to_h
    assert_equal('World', variables_hash[:name])
    assert_equal('Test Title', variables_hash[:title])
    assert_equal('42', variables_hash[:count])
    
    # Test that variables work in processing
    body, vars = obj.process(text: "Hello $name\n.h1 $title\nCount: $count")
    assert_includes(body, "Hello World")
    assert_includes(body, "Test Title")
    assert_includes(body, "Count: 42")
  end

  def test_customize_variables_global_access
    # Test that variables passed to customize are accessible via Livetext::Vars
    obj = Livetext.customize(
      mix: [],
      call: [],
      vars: { 'name' => 'World', 'title' => 'Test Title', 'count' => '42' }
    )
    
    assert_instance_of(Livetext, obj)
    
    # Test that variables are accessible via Livetext::Vars (global access)
    assert_equal('World', Livetext::Vars[:name])
    assert_equal('Test Title', Livetext::Vars[:title])
    assert_equal('42', Livetext::Vars[:count])
  end

  def test_variable_dot_access
    # Test that variables can be accessed via live.vars.myvar syntax
    obj = Livetext.customize(
      mix: [],
      call: [],
      vars: { 'name' => 'World', 'title' => 'Test Title', 'count' => '42' }
    )
    
    assert_instance_of(Livetext, obj)
    
    # Test dot access syntax
    assert_equal('World', obj.vars.name)
    assert_equal('Test Title', obj.vars.title)
    assert_equal('42', obj.vars.count)
    
    # Test that built-in variables also work
    assert_equal(Livetext::VERSION, obj.vars.Version)
    assert_equal(`hostname`.chomp, obj.vars.Hostname)
    
    # Test that respond_to? works correctly
    assert(obj.vars.respond_to?(:name))
    assert(obj.vars.respond_to?(:title))
    assert(obj.vars.respond_to?(:Version))
    assert(obj.vars.respond_to?(:nonexistent))  # Now returns true since method_missing always returns a value
  end

  def test_variable_dot_access_nonexistent
    # Test what happens when accessing a nonexistent variable with dot syntax
    obj = Livetext.customize(
      mix: [],
      call: [],
      vars: { 'name' => 'World' }
    )
    
    assert_instance_of(Livetext, obj)
    
    # Test that all access methods return the same fallback message
    assert_equal('[nonexistent is undefined]', obj.vars.nonexistent)
    assert_equal('[nonexistent is undefined]', obj.vars[:nonexistent])
    assert_equal('[nonexistent is undefined]', obj.vars.get(:nonexistent))
    
    # Test global access also returns fallback message
    assert_equal('[nonexistent is undefined]', Livetext::Vars[:nonexistent])
  end

  def test_process_text
    # Test processing text directly
    text = "Hello world\nThis is a test\n.h1 Title"
    body, vars = @live.process(text: text)
    
    assert_includes(body, "Hello world")
    assert_includes(body, "This is a test")
    # Should process the .h1 command
    assert_instance_of(Hash, vars)
  end

  def test_process_file
    # Test processing a file
    # Create a temporary test file
    require 'tempfile'
    temp_file = Tempfile.new(['test', '.lt3'])
    temp_file.write("Hello from file\n.h1 File Title")
    temp_file.close
    
    body, vars = @live.process(file: temp_file.path)
    
    assert_includes(body, "Hello from file")
    # Should process the .h1 command
    assert_instance_of(Hash, vars)
    
    temp_file.unlink
  end

  def test_process_with_file
    # Test process method with file parameter
    require 'tempfile'
    temp_file = Tempfile.new(['test', '.lt3'])
    temp_file.write("Hello from process file\n.h1 Process Title")
    temp_file.close
    
    body, vars = @live.process(file: temp_file.path)
    
    assert_includes(body, "Hello from process file")
    # Should process the .h1 command
    assert_instance_of(Hash, vars)
    
    temp_file.unlink
  end

  def test_process_with_text
    # Test process method with text parameter
    text = "Hello from process text\n.h1 Process Text Title"
    body, vars = @live.process(text: text)
    
    assert_includes(body, "Hello from process text")
    # Should process the .h1 command
    assert_instance_of(Hash, vars)
  end

  def test_process_with_vars
    # Test process method with variables
    text = "Hello $name\n.h1 $title"
    body, vars = @live.process(text: text, vars: { 'name' => 'World', 'title' => 'Test Title' })
    
    assert_includes(body, "Hello World")
    assert_includes(body, "Test Title")
    assert_equal('World', vars[:name])
    assert_equal('Test Title', vars[:title])
  end

  def test_process_error_handling
    # Test process method error cases
    assert_raises(RuntimeError) { @live.process } # No file or text
    assert_raises(RuntimeError) { @live.process(file: 'nonexistent.lt3', text: 'some text') } # Both file and text
  end

  def test_backward_compatibility
    # Test that old methods still work
    text = "Hello from old method\n.h1 Old Title"
    
    # Test transform
    result1 = @live.transform(text)
    assert_includes(result1, "Hello from old method")
    
    # Test xform with text
    result2 = @live.xform(text: text)
    assert_includes(result2, "Hello from old method")
    
    # Test xform_file
    require 'tempfile'
    temp_file = Tempfile.new(['test', '.lt3'])
    temp_file.write("Hello from old file method\n.h1 Old File Title")
    temp_file.close
    
    result3 = @live.xform_file(temp_file.path)
    assert_includes(result3, "Hello from old file method")
    
    temp_file.unlink
  end

  def test_process_returns_array
    # Test that process returns [body, vars] array
    text = "Hello $name\n.set title=\"Test Title\"\n.h1 $title"
    body, vars = @live.process(text: text, vars: { 'name' => 'World' })
    
    assert_includes(body, "Hello World")
    assert_includes(body, "Test Title")
    assert_equal('World', vars[:name])
    assert_equal('Test Title', vars[:title])
  end
end
