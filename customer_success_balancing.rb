require 'minitest/autorun'

class CustomerSuccessBalancing
  def initialize(customer_success, customers, customer_success_away)
    @customer_success = customer_success
    @customers = customers
    @customer_success_away = customer_success_away
  end

  def getAvailableCSS(customer_success, customer_success_away)
    return customer_success.select do |hash|
      !customer_success_away.include?(hash[:id])
    end
  end

  def getProcessedCSS(availables, customers)
    watchUsedCustomer = []
    watchCSCount = Hash.new(0)
    availables.sort_by! { |cs| cs[:score] }

    processedCSS = availables.map do |cs|
      cs[:count] = 0
      for customer in customers do
        if customer[:score] <= cs[:score] && !watchUsedCustomer.include?(customer[:id])
          watchUsedCustomer.push(customer[:id])
          watchCSCount[cs[:id]] += 1
        end

        cs[:count] = watchCSCount[cs[:id]] ? watchCSCount[cs[:id]] : 0
      end

      cs
    end
    processedCSS.sort_by { |value| -value[:count] }
  end

  def isFullEqualCount(processedCSS)
    counts = Hash.new(0)
    for cs in processedCSS do
      counts[cs[:count]] += 1
    end

    values = counts.values
    (values.first > 1 && values.last > 1) && values.first == values.last
  end

  def getBusiestCSS(processedCSS)
    if processedCSS.length == 0 || processedCSS.first[:count] == processedCSS.last[:count]
      return 0
    elsif isFullEqualCount(processedCSS)
      return 0
    else
      return processedCSS.first[:id]
    end
  end

  # Returns the id of the CustomerSuccess with the most customers
  def execute
    availablesCSS = getAvailableCSS(@customer_success, @customer_success_away)
    processedCSS = getProcessedCSS(availablesCSS, @customers)
    getBusiestCSS(processedCSS)
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  def test_scenario_one
    css = [{ id: 1, score: 60 }, { id: 2, score: 20 }, { id: 3, score: 95 }, { id: 4, score: 75 }]
    customers = [{ id: 1, score: 90 }, { id: 2, score: 20 }, { id: 3, score: 70 }, { id: 4, score: 40 }, { id: 5, score: 60 }, { id: 6, score: 10}]

    balancer = CustomerSuccessBalancing.new(css, customers, [2, 4])
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    css = array_to_map([11, 21, 31, 3, 4, 5])
    customers = array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60])
    balancer = CustomerSuccessBalancing.new(css, customers, [])
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    customer_success = Array.new(1000, 0)
    customer_success[998] = 100

    customers = Array.new(10000, 10)
    
    balancer = CustomerSuccessBalancing.new(array_to_map(customer_success), array_to_map(customers), [1000])
    assert_equal 999, balancer.execute
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(array_to_map([1, 2, 3, 4, 5, 6]), array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]), [])
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(array_to_map([100, 2, 3, 3, 4, 5]), array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]), [])
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(array_to_map([100, 99, 88, 3, 4, 5]), array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]), [1, 3, 2])
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(array_to_map([100, 99, 88, 3, 4, 5]), array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]), [4, 5, 6])
    assert_equal 3, balancer.execute
  end

  def test_getProcessedCSS
    balancer = CustomerSuccessBalancing.new([], [], [])

    expected = [{:id=>1, :score=>40, :count=>1}, {:id=>2, :score=>77, :count=>1}]
    assert_equal expected, balancer.getProcessedCSS(array_to_map([40, 77]), array_to_map([33, 73]))

    expected = [{:id=>2, :score=>77, :count=>2}, {:id=>1, :score=>20, :count=>0}]
    assert_equal expected, balancer.getProcessedCSS(array_to_map([20, 77]), array_to_map([77, 73]))

  def test_isFullEqualCount
    balancer = CustomerSuccessBalancing.new([], [], [])
    assert_equal true, balancer.isFullEqualCount([{:count => 1}, {:count => 1}])
    assert_equal false, balancer.isFullEqualCount([{:count => 1}, {:count => 2}])
    assert_equal false, balancer.isFullEqualCount([{:count => 1}, {:count => 1}, {:count => 2}, {:count => 3}])
    assert_equal false, balancer.isFullEqualCount([{:count => 1}, {:count => 1}, {:count => 2}, {:count => 1}])
    assert_equal true, balancer.isFullEqualCount([{:count => 1}, {:count => 1}, {:count => 1}])
  end

  def array_to_map(arr)
    out = []
    arr.each_with_index { |score, index| out.push({ id: index + 1, score: score }) }
    out
  end
end

# Minitest.run