# frozen_string_literal: true

require_relative "../test_helper"

class CostTest < Minitest::Test
  def test_cost_breakdown_detail_from_hash
    hash = {
      "neuralSearch" => 0.005,
      "deepSearch" => nil,
      "contentText" => 0.001,
      "contentHighlight" => 0.001,
      "contentSummary" => 0.001
    }

    detail = Exa::Responses::CostBreakdownDetail.from_hash(hash)

    assert_equal 0.005, detail.neural_search
    assert_nil detail.deep_search
    assert_equal 0.001, detail.content_text
    assert_equal 0.001, detail.content_highlight
    assert_equal 0.001, detail.content_summary
  end

  def test_cost_breakdown_detail_from_nil
    assert_nil Exa::Responses::CostBreakdownDetail.from_hash(nil)
  end

  def test_cost_breakdown_from_hash
    hash = {
      "search" => 0.005,
      "contents" => 0.003,
      "breakdown" => {
        "neuralSearch" => 0.005,
        "contentText" => 0.001,
        "contentHighlight" => 0.001,
        "contentSummary" => 0.001
      }
    }

    breakdown = Exa::Responses::CostBreakdown.from_hash(hash)

    assert_equal 0.005, breakdown.search
    assert_equal 0.003, breakdown.contents
    assert_instance_of Exa::Responses::CostBreakdownDetail, breakdown.breakdown
    assert_equal 0.005, breakdown.breakdown.neural_search
  end

  def test_cost_breakdown_from_nil
    assert_nil Exa::Responses::CostBreakdown.from_hash(nil)
  end

  def test_per_request_prices_from_hash
    hash = {
      "neuralSearch" => 0.005,
      "deepSearch" => 0.015
    }

    prices = Exa::Responses::PerRequestPrices.from_hash(hash)

    assert_equal 0.005, prices.neural_search
    assert_equal 0.015, prices.deep_search
  end

  def test_per_request_prices_from_nil
    assert_nil Exa::Responses::PerRequestPrices.from_hash(nil)
  end

  def test_per_page_prices_from_hash
    hash = {
      "text" => 0.001,
      "highlight" => 0.001,
      "summary" => 0.001
    }

    prices = Exa::Responses::PerPagePrices.from_hash(hash)

    assert_equal 0.001, prices.text
    assert_equal 0.001, prices.highlight
    assert_equal 0.001, prices.summary
  end

  def test_per_page_prices_from_nil
    assert_nil Exa::Responses::PerPagePrices.from_hash(nil)
  end

  def test_cost_dollars_from_hash_with_full_data
    hash = {
      "total" => 0.008,
      "breakDown" => [
        {
          "search" => 0.005,
          "contents" => 0.003,
          "breakdown" => {
            "neuralSearch" => 0.005,
            "contentText" => 0.001,
            "contentHighlight" => 0.001,
            "contentSummary" => 0.001
          }
        }
      ],
      "perRequestPrices" => {
        "neuralSearch" => 0.005,
        "deepSearch" => 0.015
      },
      "perPagePrices" => {
        "text" => 0.001,
        "highlight" => 0.001,
        "summary" => 0.001
      }
    }

    cost = Exa::Responses::CostDollars.from_hash(hash)

    assert_equal 0.008, cost.total
    assert_equal 1, cost.break_down.length
    assert_instance_of Exa::Responses::CostBreakdown, cost.break_down.first
    assert_equal 0.005, cost.break_down.first.search
    assert_instance_of Exa::Responses::PerRequestPrices, cost.per_request_prices
    assert_equal 0.005, cost.per_request_prices.neural_search
    assert_instance_of Exa::Responses::PerPagePrices, cost.per_page_prices
    assert_equal 0.001, cost.per_page_prices.text
  end

  def test_cost_dollars_from_hash_with_minimal_data
    hash = {
      "total" => 0.005
    }

    cost = Exa::Responses::CostDollars.from_hash(hash)

    assert_equal 0.005, cost.total
    assert_nil cost.break_down
    assert_nil cost.per_request_prices
    assert_nil cost.per_page_prices
  end

  def test_cost_dollars_from_nil
    assert_nil Exa::Responses::CostDollars.from_hash(nil)
  end

  def test_search_response_with_cost_dollars
    hash = {
      "requestId" => "req_123",
      "searchType" => "neural",
      "results" => [],
      "costDollars" => {
        "total" => 0.005,
        "breakDown" => [{"search" => 0.005}]
      }
    }

    response = Exa::Responses::SearchResponse.from_hash(hash)

    assert_instance_of Exa::Responses::CostDollars, response.cost_dollars
    assert_equal 0.005, response.cost_dollars.total
  end

  def test_contents_response_with_cost_dollars
    hash = {
      "requestId" => "req_456",
      "results" => [],
      "costDollars" => {
        "total" => 0.003
      }
    }

    response = Exa::Responses::ContentsResponse.from_hash(hash)

    assert_instance_of Exa::Responses::CostDollars, response.cost_dollars
    assert_equal 0.003, response.cost_dollars.total
  end

  def test_answer_response_with_cost_dollars
    hash = {
      "answer" => "Test answer",
      "citations" => [],
      "costDollars" => {
        "total" => 0.01,
        "breakDown" => [
          {"search" => 0.005, "contents" => 0.005}
        ]
      }
    }

    response = Exa::Responses::AnswerResponse.from_hash(hash)

    assert_instance_of Exa::Responses::CostDollars, response.cost_dollars
    assert_equal 0.01, response.cost_dollars.total
    assert_equal 1, response.cost_dollars.break_down.length
  end
end
