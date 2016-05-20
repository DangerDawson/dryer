RSpec.describe Dryer::Constructor do
  let(:instance) { klass.new }
  before do
    stub_const("One", Class.new)
    stub_const("Two", Class.new)
    stub_const("Three", Class.new)
    stub_const("Four", Class.new)
  end

  describe '.()' do
    let(:klass) do
      Class.new do
        include Dryer::Constructor(one: One, two: Two, three: Three)
      end
    end

    it 'assigns each constructor arg to an ivar and defines private readers' do
      expect { instance.one }.to raise_error(NoMethodError)
      expect { instance.two }.to raise_error(NoMethodError)
      expect { instance.three }.to raise_error(NoMethodError)
      expect(instance.__send__(:one)).to eq(One)
      expect(instance.__send__(:two)).to eq(Two)
      expect(instance.__send__(:three)).to eq(Three)
    end

    context "overide constructor" do
      let!(:instance) { klass.new(three: Four) }
      it 'assings the supplied value to the construstor arg' do
        expect(instance.__send__(:three)).to eq(Four)
      end

      context "it does not memoize the passed in args" do
        let!(:another_instance) { klass.new() }
        it 'assings the supplied value to the construstor arg' do
          puts "before instance"
          expect(another_instance.__send__(:three)).to eq(Three)
        end
      end
    end
  end

  describe '.Protected()' do
    let(:klass) do
      Class.new do
        include Dryer::Constructor::Protected(one: One, two: Two, three: Three)
      end
    end

    it 'assigns each constructor arg to an ivar and defines protected readers' do
      expect { instance.one }.to raise_error(NoMethodError)
      expect { instance.two }.to raise_error(NoMethodError)
      expect { instance.three }.to raise_error(NoMethodError)
      expect(instance.__send__(:one)).to eq(One)
      expect(instance.__send__(:two)).to eq(Two)
      expect(instance.__send__(:three)).to eq(Three)
    end

    context "can overide constructor" do
      let(:instance) { klass.new(three: Four) }
      it 'assings the supplied value to the construstor arg' do
        expect(instance.__send__(:three)).to eq(Four)
      end
      context "it does not memoize the passed in args" do
        let!(:another_instance) { klass.new() }
        it 'assings the supplied value to the construstor arg' do
          puts "before instance"
          expect(another_instance.__send__(:three)).to eq(Three)
        end
      end
    end
  end

  describe '.Public()' do
    let(:klass) do
      Class.new do
        include Dryer::Constructor::Public(one: One, two: Two, three: Three)
      end
    end

    it 'assigns each constructor arg to an ivar and defines public readers' do
      expect(instance.one).to eq(One)
      expect(instance.two).to eq(Two)
      expect(instance.three).to eq(Three)
      expect { instance.one }.to_not raise_error
      expect { instance.two }.to_not raise_error
      expect { instance.three }.to_not raise_error
    end

    context "can overide constructor" do
      let(:instance) { klass.new(three: Four) }
      it 'assings the supplied value to the construstor arg' do
        expect(instance.three).to eq(Four)
      end
      context "it does not memoize the passed in args" do
        let!(:another_instance) { klass.new() }
        it 'assings the supplied value to the construstor arg' do
          puts "before instance"
          expect(another_instance.__send__(:three)).to eq(Three)
        end
      end
    end
  end
end
