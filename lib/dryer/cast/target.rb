module Dryer
  module Cast
    module Target
      def initialize(sender: )
        @sender = sender
      end

      private

      attr_reader :sender
    end
  end
end
