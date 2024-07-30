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
    graph_with_default_setup(image_path:) do |graph|
      graph.title = 'USD Buy/Sell Rates'
      graph.data(:Buy, rates.map(&:buy))
      graph.data(:Sell, rates.map(&:sell))
      graph.minimum_value = rates.map(&:buy).min
      graph.maximum_value = rates.map(&:sell).max
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

  def graph_with_default_setup(image_path:)
    Gruff::Line.new(GRAPH_DIMENSIONS).tap do |graph|
      graph.show_vertical_markers = true
      graph.labels = labels
      graph.label_rotation = -45.0
      graph.hide_dots = true
      yield graph
      graph.write(image_path)
    end
    image_path
  end
end
