RSpec.describe Dryer::Cast::Base do
  describe "It can be included without a default module" do
    let(:klass) do
      Class.new do
        include Dryer::Cast.base
      end
    end

    it "Properly includes Dryer::Cast::Send" do
      expect(klass.included_modules.any?{ |m| m.is_a? Dryer::Cast::Base }).to be_truthy
    end
    it "defines the cast macro" do
      expect(klass).to respond_to(:cast)
    end

    describe "#cast" do
      context "with implicit class name" do
        let(:instance) { klass.new }
        let(:foobar) { double("Foobar", new: double(:target, call: :bar)) }
        before do
          stub_const("Foobar", foobar)
          klass.class_eval do
            cast :foobar
          end
        end
        it "defines the casted method" do
          expect(instance.foobar).to eq :bar
        end

        context "with namespace" do
          let(:klass) do
            Class.new do
              include Dryer::Cast.base(namespace: "Bar")
            end
          end
          let(:name_space_foobar) { double("Foobar", new: double(:target, call: :bar)) }
          before do
            stub_const("Bar::Foobar", foobar)
            klass.class_eval do
              cast :foobar
            end
          end
          it "defines the casted method" do
            expect(instance.foobar).to eq :bar
          end
        end

        # [:method1]
        # [method1: :local_method]
        # [method1, method2: :local_method]
        # :method1
        context "with 'with'" do
          before do
            stub_const("Bar::Foobar", foobar)
            klass.class_eval do
              cast :foobar, with: [:method1]
              def method1; "value"; end
            end
          end
          it "defines the casted method" do
            expect(foobar).to receive(:new).with(method1: instance.method1, caster: instance)
            expect(instance.foobar).to eq :bar
          end
        end
      end

      context "with explicit class name" do
        let(:instance) { klass.new }
        let(:foobar) { double("Foobar", new: double(:target, call: :bar)) }
        before do
          stub_const("Explicit", foobar)
          klass.class_eval do
            cast :foobar, to: "Explicit"
          end
        end
        it "defines the casted method" do
          expect(instance.foobar).to eq :bar
        end

        context "with namespace" do
          let(:klass) do
            Class.new do
              include Dryer::Cast.base(namespace: "Bar")
            end
          end
          before do
            klass.class_eval do
              cast :foobar, to: "Explicit"
            end
          end
          it "defines the casted method" do
            expect(instance.foobar).to eq :bar
          end
        end
      end

      context "arity" do
        let(:instance) { klass.new }
        let(:foobar_instance) { double(:target, call: :bar) }
        let(:foobar) { double("Foobar", new: foobar_instance) }
        before do
          stub_const("Foobar", foobar)
          klass.class_eval do
            cast :foobar
          end
        end

        context "with arity greater than zero" do
          it "defines the casted method" do
            expect(foobar_instance).to receive(:call).with(param: 1)
            instance.foobar(param: 1)
          end
        end
        context "with arity of zero" do
          it "defines the casted method" do
            expect(foobar_instance).to receive(:call).with(no_args)
            instance.foobar
          end
        end
      end
    end

    describe "#cast_private" do
      let(:instance) { klass.new }
      let(:foobar_instance) { double(:target, call: :bar) }
      let(:foobar) { double("Foobar", new: foobar_instance) }
      before do
        stub_const("Foobar", foobar)
        klass.class_eval do
          cast_private :foobar
        end
      end

      it "defines the casted method" do
        expect { instance.foobar }.to raise_error(NoMethodError)
        expect(instance.__send__(:foobar)).to eq(:bar)
      end
    end

    describe ".cast_methods" do
      let(:instance) { klass.new }
      let(:foobar_instance) { double(:target, call: :bar) }
      let(:foobar) { double("Foobar", new: foobar_instance) }
      before do
        stub_const("Foobar", foobar)
        klass.class_eval do
          cast :foobar
        end
      end

      it "defines the casted method" do
        expect(instance.cast_methods).to eq [:foobar]
      end

      it "defines the casted method" do
        expect(klass.cast_methods).to eq [:foobar]
      end
    end

    describe "#cast_group" do
      let(:klass_eval) do
        Proc.new do |cast_group_args|
          klass.class_eval do
            cast_group cast_group_args do
              cast :foobar
            end
          end
        end
      end
      let(:instance) { klass.new }
      let(:foobar) { double("Foobar", new: double(:target, call: :bar)) }
      let!(:cast_group_args) { {} }
      before do
        klass_eval.call(cast_group_args)
      end

      context "with no args" do
        before { stub_const("Foobar", foobar) }
        it "defines the casted method" do
          expect(instance.foobar).to eq :bar
        end
      end

      #context "with namespace" do
      #  let(:foobar) { double("Bar::Foobar", new: double(:target, call: :bar)) }
      #  let(:cast_group_args) { {namespace: "Bar"} }
      #  before { stub_const("Bar::Foobar", foobar) }
      #  it "defines the casted method" do
      #    expect(instance.foobar).to eq :bar
      #  end
      #end
    end

    # TODO: visibility
  end
end
