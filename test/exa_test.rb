# frozen_string_literal: true

require "test_helper"

class ExaTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Exa::VERSION
  end

  def test_it_has_a_placeholder_error_class
    assert_raises(Exa::Error) { raise Exa::Error }
  end
end
