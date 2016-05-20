RSpec.describe Dryer::Cast::Base do

  describe "It can be included without a default module" do
    let(:klass) do
      Class.new do
        include Dryer::Cast.base()
      end
    end

    it "Properly includes Dryer::Cast::Send" do
      expect(klass.included_modules.any?{ |m| m.is_a? Dryer::Cast::Base } ).to be_truthy
    end
  end
end
