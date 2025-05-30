# frozen_string_literal: true

require 'zeitwerk'

loader = Zeitwerk::Loader.new
loader.push_dir(File.expand_path('..', __dir__))
loader.push_dir(File.expand_path('../models', __dir__))
loader.ignore(File.expand_path('../initializers', __dir__))
loader.setup
