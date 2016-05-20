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
        let(:intance) { klass.new }
        let(:foobar) { double("Foobar", new: double(:target, call: :bar)) }
        before do
          stub_const("Foobar", foobar)
          klass.class_eval do
            cast :foobar
          end
        end
        it "defines the casted method" do
          expect(intance.foobar).to eq :bar
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
            expect(intance.foobar).to eq :bar
          end
        end
      end

      context "with explicit class name" do
        let(:intance) { klass.new }
        let(:foobar) { double("Foobar", new: double(:target, call: :bar)) }
        before do
          stub_const("Explicit", foobar)
          klass.class_eval do
            cast :foobar, class_name: "Explicit"
          end
        end
        it "defines the casted method" do
          expect(intance.foobar).to eq :bar
        end

        context "with namespace" do
          let(:klass) do
            Class.new do
              include Dryer::Cast.base(namespace: "Bar")
            end
          end
          before do
            klass.class_eval do
              cast :foobar, class_name: "Explicit"
            end
          end
          it "defines the casted method" do
            expect(intance.foobar).to eq :bar
          end
        end
      end

      context "arity" do
        let(:intance) { klass.new }
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
            intance.foobar(param: 1)
          end
        end
        context "with arity of zero" do
          it "defines the casted method" do
            expect(foobar_instance).to receive(:call).with(no_args)
            intance.foobar
          end
        end
      end
    end
  end
end

# arity
