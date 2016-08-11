RSpec.describe Dryer::Dependency do
  let(:klass_one) do
    Class.new do
      def initialize
        freeze
                end
    end
  end
  let(:klass_two) do
    Class.new do
      def initialize
        freeze
                end
    end
  end
  let(:dependency_args) { [one: klass_one, two: klass_two] }
  let(:klass_eval) do
    proc do |args|
      Class.new do
        include Dryer::Dependency
        dependencies(args)
      end
    end
  end
  let!(:klass) { klass_eval.call(*dependency_args) }

  it "Properly includes Dryer::Dependency" do
    expect(klass.included_modules.any? { |m| m == Dryer::Dependency }).to be_truthy
  end

  it "has the correct ancestory chain" do
    expect(klass.ancestors[0]).to eq klass
    expect(klass.ancestors[1]).to eq Dryer::Dependency
  end

  describe "#get_dependencies" do
    it "should return the dependencies that have been setup" do
      expect(klass.get_dependencies).to eq Hash[*dependency_args]
    end
  end

  describe ".one" do
    subject { klass.new }

    context "method access" do
      it "should setup a private method with the dependency" do
        expect(subject.__send__(:one)).to be_instance_of(klass_one)
      end

      it "should raise if method accessed publicly" do
        expect { subject.one }.to raise_error(NoMethodError)
      end
    end

    context "singleton storage" do
      let(:another_instance) { klass.new }
      it "should only create one instance of the depedency" do
        object_id_1 = subject.__send__(:one).object_id
        object_id_2 = another_instance.__send__(:one).object_id
        expect(object_id_1).to eq object_id_2
      end
    end

    context "unfrozen dependencies" do
      let(:klass_one) { Class.new } # overriding it with not freeze on init
      it "does not allow unfrozen dependencies" do
        expect { subject.__send__(:one) }.to raise_error(Dryer::Shared::DeepFreeze::Error)
      end
    end
  end

  describe "clear_singleton_storage" do
    subject { klass.new }

    it "clears the singleton storage" do
      subject.__send__(:one)
      expect(Dryer::Shared::SingletonStorage.storage.all?(&:empty?)).to eq false
      described_class.clear_singleton_storage
      expect(Dryer::Shared::SingletonStorage.storage.all?(&:empty?)).to eq true
    end
  end
end
