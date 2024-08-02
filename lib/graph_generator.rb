# frozen_string_literal: true

require 'gruff'

# Graph generator adapter class
class GraphGenerator
  GRAPH_DIMENSIONS = '1280x720'

  def initialize(rates:)
    @rates = rates
  end

  attr_reader :rates

  # Generate graph of last rates
  def buy_sell_graph(image_path: 'rates.png')
    graph_with_default_setup(graph_class: Gruff::Candlestick, image_path:) do |graph|
      rates.each do |rate|
        graph.data(low: rate.buy, high: rate.sell, open: rate.buy, close: rate.sell)
      end
      graph.title = "USD Rates\n#{rates.last.buy}/#{rates.last.sell}"
      # graph.data(:Buy, rates.map(&:buy))
      # graph.data(:Sell, rates.map(&:sell))
      graph.minimum_value = rates.map(&:buy).min - 0.15
      graph.maximum_value = rates.map(&:sell).max + 0.15
    end
  end

  # Generate graph of last Sell/Buy ratios
  def ratio_graph(image_path: 'ratios.png')
    data_points = rates.map { |rate| ((rate.sell / rate.buy) - 1).round(4) * 100 }
    graph_with_default_setup(image_path:) do |graph|
      graph.title = 'USD Sell/Buy Ratios'
      graph.data(:Ratio, data_points)
      graph.minimum_value = data_points.min
      graph.maximum_value = data_points.max
    end
  end

  def diff_graph(image_path: 'diff.png')
    data_points = rates.map { |rate| (NBU_LIMIT * ((1.0 / rate.buy) - (1.0 / rate.sell))).round(2) }
    graph_with_default_setup(image_path:) do |graph|
      graph.title = 'Conversion difference, $'
      graph.data(:Difference, data_points)
      graph.minimum_value = data_points.min
      graph.maximum_value = data_points.max
    end
  end

  def graph_with_default_setup(graph_class: Gruff::Line, image_path:)
    graph_class.new(GRAPH_DIMENSIONS).tap do |graph|
      graph.show_vertical_markers = true if graph.is_a?(Gruff::Line)
      graph.labels = labels
      graph.label_rotation = -45.0
      graph.hide_dots = true if graph.is_a?(Gruff::Line)
      yield graph
      graph.write(image_path)
    end
    image_path
  end
end
