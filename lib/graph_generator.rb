# frozen_string_literal: true

require 'gruff'
require_relative 'calculation_helpers'

# Graph generator adapter class
class GraphGenerator
  include CalculationHelpers

  GRAPH_DIMENSIONS = '1280x720'

  def initialize(rates:)
    @rates = rates
  end

  attr_reader :rates

  # Generate graph of last rates
  def buy_sell_graph(image_path: 'rates.png')
    candlestick_graph(image_path:) do |graph|
      rates.each do |rate|
        if rate.id == min_diff_id(rates)
          next graph.data(low: rate.buy, high: rate.sell, open: rate.sell, close: rate.buy)
        end

        graph.data(low: rate.buy, high: rate.sell, open: rate.buy, close: rate.sell)
      end
      graph.title = "USD Rates\n#{rates.last.buy}/#{rates.last.sell}"
      graph.y_axis_increment = 0.1
      graph.minimum_value =  min_rate_in_increments(rates, 0.1)
    end
  end

  # Generate graph of last Sell/Buy ratios
  def ratio_graph(image_path: 'ratios.png')
    data_points = rates.map { |rate| ratio(rate) }
    line_graph(image_path:) do |graph|
      graph.title = 'USD Sell/Buy Ratios'
      graph.data(:Ratio, data_points)
      graph.minimum_value = data_points.min
      graph.maximum_value = data_points.max
    end
  end

  def diff_graph(image_path: 'diff.png')
    data_points = rates.map { |rate| conversion_diff(rate) }
    line_graph(image_path:) do |graph|
      graph.title = 'Conversion difference, $'
      graph.data(:Difference, data_points)
      graph.minimum_value = data_points.min
      graph.maximum_value = data_points.max
    end
  end

  # Common setup for all graphs
  def graph_with_common_setup(image_path:, graph_class:)
    graph_class.new(GRAPH_DIMENSIONS).tap do |graph|
      graph.labels = labels
      graph.label_rotation = -45.0
      graph.marker_font_size = 14
      graph.marker_color = 'grey'
      yield graph
      graph.write(image_path)
    end
    image_path
  end

  # Common setup for Line graphs
  def line_graph(image_path:)
    graph_with_common_setup(image_path:, graph_class: Gruff::Line) do |graph|
      graph.show_vertical_markers = true
      graph.hide_dots = true
      yield graph
    end
  end

  # Common setup for Candlestick graphs
  def candlestick_graph(image_path:)
    graph_with_common_setup(image_path:, graph_class: Gruff::Candlestick) do |graph|
      graph.spacing_factor = 0
      graph.fill_opacity = 0.75
      yield graph
    end
  end

  # Graph labels in mm/dd format, one for each date
  def labels
    @labels ||= rates
                .map { |rate| rate.created_at.strftime('%m/%d') }
                .each_with_index
                .chunk_while { |date1, date2| date1[0] == date2[0] }
                .to_h { |chunk| chunk.first.reverse }
  end
end
