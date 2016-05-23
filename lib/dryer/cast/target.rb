module Dryer
  module Cast
    module Target
      def initialize(caster: )
        @caster = caster
      end

      private

      attr_reader :caster
    end
  end
end
