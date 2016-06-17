RSpec.describe Dryer::Construct do
  let(:constructor_args) { [:one, two: 2] }
  let(:include_args) {}
  let(:klass_eval) do
    proc do |args, _args2, &block|
      Class.new do
        include Dryer::Construct
        construct(*args, &block)
      end
    end
  end
  let!(:klass) { klass_eval.call(constructor_args, include_args) }

  it "Properly includes Dryer::Constructor" do
    expect(klass.included_modules.any? { |m| m == Dryer::Construct }).to be_truthy
  end

  it "has the correct ancestory chain" do
    expect(klass.ancestors[0]).to eq klass
    expect(klass.ancestors[1]).to eq Dryer::Construct
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

    context "with block param" do
      let(:constructor_args) { [vehicle: "car"] }
      let(:block) { proc { @vehicle = vehicle.capitalize } }
      let!(:klass) { klass_eval.call(constructor_args, include_args, &block) }
      let(:instance) { klass.new }

      it "has acess to instance variables" do
        expect(instance.send(:vehicle)).to eq("Car")
      end
    end

    context "public accessors" do
      let(:instance) { klass.new(one: 1, required_public: 3) }
      let(:klass_eval) do
        proc do |args, _args2, &block|
          Class.new do
            include Dryer::Construct
            construct(*args, &block).public(:required_public, optional_public: 4)
          end
        end
      end

      it "can access public accessors" do
        expect { instance.one }.to raise_error(NoMethodError)
        expect { instance.two }.to raise_error(NoMethodError)
        expect(instance.__send__(:one)).to eq 1
        expect(instance.__send__(:two)).to eq 2
        expect(instance.required_public).to eq 3
        expect(instance.optional_public).to eq 4
      end

      context "required public keyword missing" do
        let(:instance) { klass.new(one: 1) }

        it "warns of missing keyword" do
          expect { instance }.to raise_error(ArgumentError, "missing keyword(s): required_public")
        end
      end
    end

    context "freeze param" do
      let(:instance) { klass.new(instance1: "foo", instance2: "base") }
      let(:klass_eval) do
        proc do |args, args2, &block|
          Class.new do
            include Dryer::Construct.config(*args2)
            construct(*args, &block)
          end
        end
      end

      let(:klass_eval2) do
        proc do |args, &block|
          Class.new do
            include Dryer::Construct
            construct(*args, &block)
          end
        end
      end
      let!(:klass2) { klass_eval2.call(constructor_args) }
      let(:instance2) { klass2.new(instance1: "foo", instance2: "base") }

      context "without specify freeze" do
        let(:constructor_args) { [:instance1, :instance2] }
        it "setups constructor correctly" do
          expect(instance.frozen?).to be_truthy
          expect(instance2.frozen?).to be_truthy
        end
        context "with freeze false" do
          let(:include_args) { [freeze: false] }
          it "setups constructor correctly" do
            expect(instance.frozen?).to be_falsey
            expect(instance2.frozen?).to be_truthy
          end
        end
      end
    end

    describe "#before_freeze" do
      let(:instance) { klass.new(one: "foo") }
      let(:klass_eval) do
        proc do |args, _args2, &block|
          Class.new do
            include Dryer::Construct
            construct(*args, &block)
            before_freeze do
              @before_freeze = "foo"
            end
            def after_freeze
              @after_freeze ||= "bar"
            end
          end
        end
      end

      it "can set an instance variable on a pre frozen object" do
        expect(instance.instance_variable_get(:@before_freeze)).to eq("foo")
      end

      it "can not set an instance variable on a pre frozen object" do
        msg = "can't modify frozen #{klass}"
        expect { instance.after_freeze }.to raise_error(RuntimeError, msg)
      end
    end
  end
end
