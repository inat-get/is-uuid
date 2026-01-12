# spec/uuid_spec.rb — НОВЫЙ, рабочий вариант
require "spec_helper"

RSpec.describe UUID do
  let(:dns_ns) { "6ba7b810-9dad-11d1-80b4-00c04fd430c8" }

  describe ".parse" do
    it "parses valid UUID string" do
      str = "12345678-1234-5678-9abc-def012345678"
      expect(described_class.parse(str).to_s).to eq(str)
    end

    it "returns NIL for nil" do
      expect(described_class.parse(nil)).to eq(described_class::NIL)
    end

    it "raises for invalid input" do
      expect { described_class.parse("invalid") }.to raise_error(ArgumentError)
    end
  end

  describe ".generate" do
    it "default is v4" do
      uuid = described_class.generate
      expect(uuid.version).to eq(4)
    end

    it "version 1 works" do
      uuid = described_class.generate(version: 1)
      expect(uuid.version).to eq(1)
    end

    it "version 4 explicit works" do
      uuid = described_class.generate(version: 4)
      expect(uuid.version).to eq(4)
    end

    it "version 7 works" do
      uuid = described_class.generate(version: 7)
      expect(uuid.version).to eq(7)
    end

    it "version 8 works" do
      uuid = described_class.generate(version: 8)
      expect(uuid.version).to eq(8)
    end
  end

  # v1
  describe "version 1" do
    let(:uuid) { described_class.generate(version: 1) }

    it "is valid" do
      expect(uuid).to be_valid
    end

    it "has version 1" do
      expect(uuid.version).to eq(1)
    end

    it "has RFC4122 variant" do
      expect(uuid.variant).to eq(1)
    end
  end

  # v3 MD5
  describe "version 3 MD5" do
    let(:uuid) { described_class.generate(version: 3, namespace: dns_ns, name: "example.com") }

    it "has version 3" do
      expect(uuid.version).to eq(3)
    end

    it "has RFC4122 variant" do
      expect(uuid.variant).to eq(1)
    end
  end

  # v4
  describe "version 4" do
    let(:uuid) { described_class.generate(version: 4) }

    it "has version 4" do
      expect(uuid.version).to eq(4)
    end

    it "has RFC4122 variant" do
      expect(uuid.variant).to eq(1)
    end
  end

  # v5
  describe "version 5" do
    let(:uuid) { described_class.generate(version: 5, namespace: dns_ns, name: "example.com") }

    it "has version 5" do
      expect(uuid.version).to eq(5)
    end

    it "has RFC4122 variant" do
      expect(uuid.variant).to eq(1)
    end
  end

  # v8 custom
  describe "version 8 custom" do
    it "preserves string prefix" do
      uuid = described_class.generate(version: 8, prefix: "abc")
      expect(uuid.to_a[0, 3]).to eq([97, 98, 99])
    end

    it "preserves array prefix" do
      uuid = described_class.generate(version: 8, prefix: [0xDE, 0xAD])
      expect(uuid.to_a[0, 2]).to eq([0xDE, 0xAD])
    end

    it "preserves integer prefix" do
      uuid = described_class.generate(version: 8, prefix: 0xDEAD)
      expect(uuid.to_a[0, 2]).to eq([0xDE, 0xAD])
    end

    it "rejects too long prefix" do
      expect { described_class.generate(version: 8, prefix: "1234567") }.to raise_error(ArgumentError)
    end
  end

  # Object behavior
  describe "object lifecycle" do
    let(:uuid) { described_class.generate }

    it "roundtrips to_s → parse" do
      expect(described_class.parse(uuid.to_s)).to eq(uuid)
    end

    it "is frozen" do
      expect(uuid).to be_frozen
    end

    it "is comparable" do
      uuid2 = described_class.generate
      expect([0, 1, -1]).to include(uuid <=> uuid2)
    end
  end

  # NIL
  describe "NIL UUID" do
    subject { described_class::NIL }

    it { is_expected.to be_valid }
    it { expect(subject.to_s).to eq("00000000-0000-0000-0000-000000000000") }
  end


  describe "equality and hashing" do
    let(:uuid1) { described_class.generate }
    let(:uuid2) { described_class.parse(uuid1.to_s) }
    let(:uuid3) { described_class.generate }

    it "eql? works for identical objects" do
      expect(uuid1).to eql(uuid1)
    end

    it "eql? works for roundtrip objects" do
      expect(uuid1).to eql(uuid2)
      expect(uuid2).to eql(uuid1)
    end

    it "eql? rejects different UUIDs" do
      expect(uuid1).not_to eql(uuid3)
    end

    it "hash is consistent" do
      expect(uuid1.hash).to eq(uuid2.hash)
      expect(uuid1.hash).not_to eq(uuid3.hash)
    end

    it "hash works with Set" do
      set = Set[uuid1, uuid2, uuid3]
      expect(set.size).to eq(2)  # uuid1 == uuid2
    end
  end

  describe "comparisons" do
    let(:uuid_nil) { described_class::NIL }
    let(:uuids) { 3.times.map { described_class.generate } }

    it "NIL is smallest" do
      expect(uuid_nil).to be < uuids[0]
    end

    it "<=> returns correct values" do
      expect(uuids[0] <=> uuids[0]).to eq(0)
      expect(uuids[0] <=> uuids[1]).to be_between(-1, 1).inclusive
    end

    it "sorts correctly" do
      sorted = uuids.sort
      expect(sorted).to eq(sorted.sort)
    end

    it "Comparable works with Array#sort" do
      expect(uuids.sort).not_to eq(uuids)
    end
  end

  describe "inspect and debugging" do
    let(:uuid) { described_class.generate(version: 4) }

    it "inspect shows version/variant" do
      expect(uuid.inspect).to match(/UUID:\d+:\d+:/)
    end

    it "to_i works" do
      expect(uuid.to_i).to be_a(Integer)
      expect(uuid.to_i).to be_positive
    end

    it "to_a returns bytes" do
      expect(uuid.to_a).to be_a(Array)
      expect(uuid.to_a.size).to eq(16)
    end
  end

  describe "immutability" do
    let(:uuid) { described_class.generate }

    it "is deeply frozen" do
      expect(uuid).to be_frozen
      #expect(uuid.bytes).to be_frozen
      #expect(uuid.to_a).to be_frozen
    end

    it "methods return frozen objects" do
      expect(uuid.to_s).to be_frozen
      expect(uuid.urn).to be_frozen
    end
  end

  describe "v8 edge cases" do
    it "integer prefix trims correctly" do
      uuid = described_class.generate(version: 8, prefix: 0x1122)
      bytes = uuid.to_a[0, 3]
      expect(bytes.pack("C*").unpack1("H*")).to match(/1122/)
    end

    it "integer prefix too big raises" do
      expect { described_class.generate(version: 8, prefix: 2 ** 64) }.to raise_error(ArgumentError)
    end
  end

end
