require 'minitest/autorun'
require_relative '../../lib/livetext'

class TestFunctionAPIAccess < Minitest::Test
  def setup
    @live = Livetext.new
    @live.vars.set(:View, "test_view")
    @live.vars.set(:"post.id", "0001")
  end

  def test_scriptorium_image_scenario
    # This test mimics the exact scenario from Scriptorium's image function
    # Define the asset function directly in Livetext::Functions (like in Scriptorium)
    Livetext::Functions.class_eval do
      def asset(param)
        # Get view and post information (exactly like in Scriptorium)
        vname = self.class.api.vars.to_h[:View]
        postid = self.class.api.vars.to_h[:"post.id"]
        "assets/#{postid}/#{param}"  # Simplified version of the asset function
      end
    end

    # Test calling it through api.funcs (like the image function in Scriptorium)
    result = @live.api.funcs.asset("test.jpg")
    
    assert_equal "assets/0001/test.jpg", result
  end

  def test_function_can_access_api_vars
    # Define a function that needs access to api.vars (like the asset function in Scriptorium)
    Livetext::Functions.class_eval do
      def test_asset_function(param)
        # This mimics the asset function from Scriptorium that needs api.vars
        vname = api.vars.to_h[:View]
        postid = api.vars.to_h[:"post.id"]
        "view=#{vname}, post=#{postid}, file=#{param}"
      end
    end

    # Test calling it through api.funcs (like the image function in Scriptorium)
    result = @live.api.funcs.test_asset_function("test.jpg")
    
    assert_equal "view=test_view, post=0001, file=test.jpg", result
  end

  def test_function_can_access_api_vars_without_params
    # Define a function that needs access to api.vars but takes no parameters
    Livetext::Functions.class_eval do
      def test_view_info
        vname = api.vars.to_h[:View]
        postid = api.vars.to_h[:"post.id"]
        "view=#{vname}, post=#{postid}"
      end
    end

    # Test calling it through api.funcs
    result = @live.api.funcs.test_view_info()
    
    assert_equal "view=test_view, post=0001", result
  end

  def test_function_handles_missing_api_gracefully
    # Define a function that tries to access api but it's not set
    Livetext::Functions.class_eval do
      def test_no_api
        if self.class.api
          "api available"
        else
          "no api"
        end
      end
    end

    # Clear the api to test the fallback
    Livetext::Functions.api = nil

    # Test calling it through api.funcs - should still work because we set it in method_missing
    result = @live.api.funcs.test_no_api()
    
    assert_equal "api available", result
  end
end