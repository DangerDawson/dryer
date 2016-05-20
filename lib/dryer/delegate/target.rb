module Dryer
  module Delegate
    module Target
      def initialize(sender: )
        @sender = sender
      end

      private

      attr_reader :sender
    end
  end
end

