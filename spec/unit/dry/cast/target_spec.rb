RSpec.describe Dryer::Constructor do
  let(:constructor_args) { [:one, two: 2] }
  let(:klass_eval) do
    proc do |args|
      Class.new do
        include Dryer::Constructor(*args)
      end
    end
  end
  let!(:klass) { klass_eval.call(constructor_args) }

  it "Properly includes Dryer::Constructor" do
    expect(klass.included_modules.any?{ |m| m.is_a? Dryer::Constructor }).to be_truthy
  end

  describe ".()" do
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
  end

  describe ".Public()" do
    let(:klass_eval) do
      proc do |args|
        Class.new do
          include Dryer::Constructor::Public(*args)
        end
      end
    end

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
        expect(instance.one).to eq 1
        expect(instance.two).to eq 2
      end
    end

    context "both required and optional args supplied" do
      let(:instance) { klass.new(one: 1, two: 3) }

      it "setups constructor correctly" do
        expect(instance.one).to eq 1
        expect(instance.two).to eq 3
      end
    end

    context "no args" do
      let(:instance) { klass.new }
      let(:constructor_args) {}

      it "setups constructor correctly" do
        expect { instance }.to_not raise_error
      end
    end
  end

  describe ".Protected()" do
    let(:klass_eval) do
      proc do |args|
        Class.new do
          include Dryer::Constructor::Protected(*args)
        end
      end
    end

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
  end
end
