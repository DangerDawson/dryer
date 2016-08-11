RSpec.describe Dryer::Dependency do
  let(:klass_one) { Class.new }
  let(:klass_two) { Class.new }
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
    context "method access" do
      subject { klass.new }
      it "should setup a private method with the dependency" do
        expect(subject.__send__(:one)).to be_instance_of(klass_one)
      end

      it "should raise if method accessed publicly" do
        expect { subject.one }.to raise_error(NoMethodError)
      end
    end
  end
end
