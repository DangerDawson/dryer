RSpec.describe Dryer::Shared::SingletonStorage do
  describe "storage" do
    it "is a concurrent array" do
      expect(described_class.storage).to be_kind_of(Concurrent::Array)
    end
  end

  describe "register" do
    it "returns a concurrent hash" do
      expect(described_class.register).to be_kind_of(Concurrent::Hash)
    end

    it "registers itself" do
      hash = described_class.register
      expect(described_class.storage).to include(hash)
    end
  end

  describe "clear" do
    it "clears the contents of the hash's" do
      hash1 = described_class.register
      hash2 = described_class.register
      hash1[:key] = :value
      hash2[:key2] = :value2
      described_class.clear
      expect(described_class.storage).to_not eq include
    end
  end
end
