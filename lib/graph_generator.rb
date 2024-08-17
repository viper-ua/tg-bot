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
    graph_with_default_setup(graph_class: Gruff::Candlestick, image_path:) do |graph|
      rates.each do |rate|
        next graph.data(low: rate.buy, high: rate.sell, open: rate.sell, close: rate.buy) if rate.id == min_diff_id

        graph.data(low: rate.buy, high: rate.sell, open: rate.buy, close: rate.sell)
      end
      graph.title = "USD Rates\n#{rates.last.buy}/#{rates.last.sell}"
      graph.minimum_value = rates.map(&:buy).min
      graph.spacing_factor = 0
      graph.marker_font_size = 14
    end
  end

  # Generate graph of last Sell/Buy ratios
  def ratio_graph(image_path: 'ratios.png')
    data_points = rates.map { |rate| ratio(rate) }
    graph_with_default_setup(image_path:) do |graph|
      graph.title = 'USD Sell/Buy Ratios'
      graph.data(:Ratio, data_points)
      graph.minimum_value = data_points.min
      graph.maximum_value = data_points.max
    end
  end

  def diff_graph(image_path: 'diff.png')
    data_points = rates.map { |rate| conversion_diff(rate) }
    graph_with_default_setup(image_path:) do |graph|
      graph.title = 'Conversion difference, $'
      graph.data(:Difference, data_points)
      graph.minimum_value = data_points.min
      graph.maximum_value = data_points.max
    end
  end

  def graph_with_default_setup(image_path:, graph_class: Gruff::Line)
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

  def labels
    @labels ||= rates
                .pluck('DATE(created_at)')
                .each_with_index
                .chunk_while { |date1, date2| date1[0] == date2[0] }
                .to_h { |chunk| chunk.first.reverse }
                .transform_values { |v| v.split('-')[1..].join('/') }
  end

  def min_diff_id = rates.min_by { |rate| rate.sell - rate.buy }.id
end
