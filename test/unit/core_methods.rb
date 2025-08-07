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
