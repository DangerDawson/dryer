# The purpose of this class is to ensure super(**initialize_args) does not throw an error
# by ensuring that the default initialize takes args for all parent classes
module Dryer
  module Construct
    module BaseInitialize
      def _initialize_without_freeze(_args)
      end
    end
  end
end
