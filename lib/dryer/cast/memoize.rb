module Dryer
  module Cast
    module Memoize
      def initialize(*args)
        @_memoize_storage = {}
        super(*args)
      end
    end
  end
end
