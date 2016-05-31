RSpec.describe Dryer::Cast do
  describe "It can be included without a default module" do
    let(:klass) do
      Class.new do
        include Dryer::Cast
        def self.name
          "CasterClass"
        end
      end
    end

    it "Properly includes Dryer::Cast::Send" do
      expect(klass.included_modules.any?{ |m| m == Dryer::Cast }).to be_truthy
    end
    it "defines the cast macro" do
      expect(klass).to respond_to(:cast)
    end

    describe "#cast" do
      let(:instance) { klass.new }
      let(:to) { "Foobar" }
      let(:foobar_instance) { double(:target, call: :bar) }
      let(:foobar) { double(to, new: foobar_instance) }
      let(:method) { :foobar }
      let(:cast_args) { { to: to } }
      let(:klass_eval) do
        proc do |method, cast_args|
          klass.class_eval do
            cast method, cast_args
          end
        end
      end

      before do
        klass_eval.call(method, cast_args)
        stub_const(to, foobar)
      end

      it "defines the casted method" do
        expect(instance.foobar).to eq :bar
      end

      context "param 'to': not present" do
        let(:cast_args) {}

        it "infers the to class from the name" do
          expect(instance.foobar).to eq :bar
        end
      end

      context "arity" do
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

      context "param 'memoize:'" do
        let(:cast_args) { { to: to, memoize: true } }
        let(:foobar_instance) { double(:target, call: false) }

        it "defines the casted method" do
          expect(foobar).to receive(:new).once
          expect(instance.foobar).to eq false
          expect(instance.foobar).to eq false
        end

        context "when caster is frozen" do
          before { instance.freeze }
          it "defines the casted method" do
            expect(foobar).to receive(:new).once
            expect(instance.foobar).to eq false
            expect(instance.foobar).to eq false
          end
        end

        context "when memoize is not enabled" do
          let(:cast_args) { { to: to, memoize: false } }
          it "defines the casted method" do
            expect(foobar).to receive(:new).twice
            expect(instance.foobar).to eq false
            expect(instance.foobar).to eq false
          end
        end

        # For situations where it is not possible to initialize the storage before the
        # constructor is intialized e.g. ActiveRecord
        context "when storage is not set as part of the initialize" do
          it "defines the casted method" do
            instance.remove_instance_variable(:@_memoize_storage)
            expect(foobar).to receive(:new).once
            expect(instance.foobar).to eq false
            expect(instance.foobar).to eq false
          end
        end
      end

      context "param 'with:'" do
        let(:with_args) { [:method] }
        let(:cast_args) { { to: to, with: with_args } }
        before do
          klass.class_eval do
            def method
              "value"
            end

            def local_method
              "another_value"
            end
          end
        end

        it "defines the casted method" do
          expect(foobar).to receive(:new).with(method: instance.method)
          expect(instance.foobar).to eq :bar
        end

        context "single arg" do
          let(:with_args) { :method }
          it "defines the casted method" do
            expect(foobar).to receive(:new).with(method: instance.method)
            expect(instance.foobar).to eq :bar
          end
        end

        context "hash arg" do
          let(:with_args) { [method: :local_method] }

          it "defines the casted method" do
            expect(foobar).to receive(:new).with(method: instance.local_method)
            expect(instance.foobar).to eq :bar
          end
        end

        context "mixed args" do
          let(:with_args) { [:method, another_method: :local_method] }

          it "defines the casted method" do
            expected_args = { method: instance.method, another_method: instance.local_method }
            expect(foobar).to receive(:new).with(expected_args)
            expect(instance.foobar).to eq :bar
          end
        end

        context "no args" do
          let(:with_args) {}

          it "defines the casted method" do
            expect(foobar).to receive(:new)
            expect(instance.foobar).to eq :bar
          end
        end

        context "with :self" do
          let(:with_args) { [method: :self] }

          it "defines the casted method" do
            expected_args = { method: instance }
            expect(foobar).to receive(:new).with(expected_args)
            expect(instance.foobar).to eq :bar
          end
        end
      end

      context "param 'access:'" do
        let(:cast_args) { { to: to, access: access_args } }

        context "public" do
          let(:access_args) { :public }

          it "ensures the cast method is public" do
            expect(instance.foobar).to eq :bar
          end
        end

        context "private" do
          let(:access_args) { :private }

          it "ensures the cast method is private" do
            expect { instance.foobar }.to raise_error(NoMethodError)
            expect(instance.__send__(:foobar)).to eq(:bar)
          end
        end

        context "no args" do
          let(:cast_args) { { to: to } }

          it "ensures the cast method is public" do
            expect(instance.foobar).to eq :bar
          end
        end
      end
    end

    describe "#cast_group" do
      let(:klass_eval) do
        proc do |cast_group_args, cast_args|
          klass.class_eval do
            cast_group cast_group_args do
              cast :foobar, cast_args
            end
            def method
              "value"
            end
          end
        end
      end
      let(:instance) { klass.new }
      let(:foobar) { double("Foobar", new: double(:target, call: :bar)) }
      let!(:cast_group_args) { {} }
      let!(:cast_args) { {} }
      before do
        klass_eval.call(cast_group_args, cast_args)
      end

      context "with no args" do
        before { stub_const("Foobar", foobar) }
        it "defines the casted method" do
          expect(instance.foobar).to eq :bar
        end
      end

      context "with namespace:" do
        let(:foobar) { double("Bar::Foobar", new: double(:target, call: :bar_foobar)) }
        let(:cast_group_args) { { namespace: "Bar" } }
        before { stub_const("Bar::Foobar", foobar) }
        it "defines the casted method" do
          expect(instance.foobar).to eq :bar_foobar
        end
      end

      context "with namespace and explicit to:" do
        let(:foobar) { double("Bar::Zebra", new: double(:target, call: :bar_zebra)) }
        let(:cast_group_args) { { namespace: "Bar" } }
        let(:cast_args) { { to: "Zebra" } }
        before { stub_const("Bar::Zebra", foobar) }
        it "defines the casted method" do
          expect(instance.foobar).to eq :bar_zebra
        end
      end

      context "with access:" do
        let(:foobar) { double("Foobar", new: double(:target, call: :foobar)) }
        let(:cast_group_args) { { access: :private } }
        before { stub_const("Foobar", foobar) }
        it "defines the casted method" do
          expect { instance.foobar }.to raise_error(NoMethodError)
          expect(instance.__send__(:foobar)).to eq(:foobar)
        end
      end

      context "with with:" do
        let(:foobar) { double("Foobar", new: double(:target, call: :foobar)) }
        let(:cast_group_args) { { with: :method } }
        before { stub_const("Foobar", foobar) }
        it "defines the casted method" do
          expect(foobar).to receive(:new).with(method: instance.method)
          expect(instance.foobar).to eq :foobar
        end
      end

      describe "#cast_methods" do
        let(:to) { "Foobar" }
        let!(:cast_group_args) { { with: :foo } }
        let(:cast_args) { { to: to } }
        context "without specify memoize" do
          it "defines the casted method" do
            expected = { foobar: { to: "Foobar", with: [:foo], memoize: false } }
            expect(klass.cast_methods).to eq expected
          end
        end

        context "with specified memoize" do
          let!(:cast_group_args) { { with: :foo, memoize: true } }
          it "defines the casted method" do
            expected = { foobar: { to: "Foobar", with: [:foo], memoize: true } }
            expect(klass.cast_methods).to eq expected
          end
        end
      end
    end

    describe "#nested_cast_group" do
      let(:klass_eval) do
        proc do |cast_group_args, cast_group_args2, cast_args|
          klass.class_eval do
            cast_group cast_group_args do
              cast_group cast_group_args2 do
                cast :foobar, cast_args
              end
            end
            def method1
              "method1"
            end

            def method2
              "method2"
            end

            def method3
              "method3"
            end

            def method4
              "method4"
            end
          end
        end
      end

      let(:instance) { klass.new }
      let(:foobar) { double("Foobar", new: double(:target, call: :bar)) }
      let!(:cast_group_args) { {} }
      let!(:cast_group_args2) { {} }
      let!(:cast_args) { {} }
      before do
        klass_eval.call(cast_group_args, cast_group_args2, cast_args)
      end

      context "with no args" do
        before { stub_const("Foobar", foobar) }
        it "defines the casted method" do
          expect(instance.foobar).to eq :bar
        end
      end

      context "with args" do
        let(:foobar) { double("Bar::Foobar", new: double(:target, call: :bar)) }
        let!(:cast_group_args) { { namespace: "Bar" } }
        let!(:cast_group_args2) { { with: :method1 } }
        before { stub_const("Bar::Foobar", foobar) }
        it "defines the casted method" do
          expect(foobar).to receive(:new).with(method1: instance.method1)
          expect(instance.foobar).to eq :bar
        end
      end

      context "with args multiple 'with'" do
        let(:foobar) { double("Foobar", new: double(:target, call: :bar)) }
        let!(:cast_group_args) { { with: [:method1, :method2] } }
        let!(:cast_group_args2) { { with: :method3 } }
        before { stub_const("Foobar", foobar) }
        it "defines the casted method" do
          expect(foobar).to receive(:new).with(
            method1: instance.method1,
            method2: instance.method2,
            method3: instance.method3
          )
          expect(instance.foobar).to eq :bar
        end

        context "cast has 'with'" do
          let!(:cast_args) { { with: :method4 } }
          it "defines the casted method" do
            expect(foobar).to receive(:new).with(
              method1: instance.method1,
              method2: instance.method2,
              method3: instance.method3,
              method4: instance.method4
            )
            expect(instance.foobar).to eq :bar
          end
        end
      end

      context "with args multiple 'namespace'" do
        let(:foobar) { double("Foo::Bar::Foobar", new: double(:target, call: :bar)) }
        let!(:cast_group_args) { { namespace: "Foo" } }
        let!(:cast_group_args2) { { namespace: "Bar" } }
        before { stub_const("Foo::Bar::Foobar", foobar) }
        it "defines the casted method" do
          expect(foobar).to receive(:new)
          expect(instance.foobar).to eq :bar
        end

        context "cast has 'namespace'" do
          let(:foobar) { double("Foo::Bar::Car::Foobar", new: double(:target, call: :bar)) }
          let!(:cast_args) { { namespace: "Car" } }
          before { stub_const("Foo::Bar::Car::Foobar", foobar) }
          it "defines the casted method" do
            expect(foobar).to receive(:new)
            expect(instance.foobar).to eq :bar
          end
        end
      end

      context "with args multiple 'access'" do
        let(:foobar) { double("Foobar", new: double(:target, call: :bar)) }
        before { stub_const("Foobar", foobar) }

        context "[public, private]" do
          let!(:cast_group_args) { { access: :public } }
          let!(:cast_group_args2) { { access: :private } }
          it "defines the casted method" do
            expect { instance.foobar }.to raise_error(NoMethodError)
            expect(instance.__send__(:foobar)).to eq(:bar)
          end
        end

        context "[private, public]" do
          let!(:cast_group_args) { { access: :private } }
          let!(:cast_group_args2) { { access: :public } }
          it "defines the casted method" do
            expect(instance.foobar).to eq :bar
          end
        end
        context "cast has access" do
          let!(:cast_group_args) { { access: :private } }
          let!(:cast_group_args2) { { access: :public } }
          let!(:cast_args) { { access: :private } }
          it "defines the casted method" do
            expect { instance.foobar }.to raise_error(NoMethodError)
            expect(instance.__send__(:foobar)).to eq(:bar)
          end
        end
      end
    end
  end
end
