RSpec.describe Dryer::Construct do
  let(:constructor_args) { [:one, two: 2] }
  let(:klass_eval) do
    proc do |args|
      Class.new do
        include Dryer::Construct
        construct(*args)
      end
    end
  end
  let!(:klass) { klass_eval.call(constructor_args) }

  it "Properly includes Dryer::Constructor" do
    expect(klass.included_modules.any? { |m| m == Dryer::Construct }).to be_truthy
  end

  describe "construct" do
    context "missing required args" do
      let(:instance) { klass.new }
      let(:constructor_args) { [:one, :two, three: 3] }

      it "setups constructor correctly" do
        expect { instance }.to raise_error(ArgumentError, "missing keyword(s): one, two")
      end
    end

    context "only required args supplied" do
      let(:instance) { klass.new(one: 1) }

      it "setups constructor correctly" do
        expect { instance.one }.to raise_error(NoMethodError)
        expect { instance.two }.to raise_error(NoMethodError)
        expect(instance.__send__(:one)).to eq 1
        expect(instance.__send__(:two)).to eq 2
      end
    end

    context "both required and optional args supplied" do
      let(:instance) { klass.new(one: 1, two: 3) }

      it "setups constructor correctly" do
        expect { instance.one }.to raise_error(NoMethodError)
        expect { instance.two }.to raise_error(NoMethodError)
        expect(instance.__send__(:one)).to eq 1
        expect(instance.__send__(:two)).to eq 3
      end
    end

    context "no args" do
      let(:instance) { klass.new }
      let(:constructor_args) {}

      it "setups constructor correctly" do
        expect { instance }.to_not raise_error
      end
    end
    context "freeze param" do
      let(:instance) { klass.new(instance1: "foo", instance2: "base") }
      context "without specify freeze" do
        let(:constructor_args) { [:instance1, :instance2] }
        it "setups constructor correctly" do
          expect(instance.frozen?).to be_truthy
        end
        context "with freeze false" do
          let(:constructor_args) { [freeze: false] }
          it "setups constructor correctly" do
            expect(instance.frozen?).to be_falsey
          end
        end
      end
    end
  end
end
