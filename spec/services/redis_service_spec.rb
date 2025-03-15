require "rails_helper"

RSpec.describe RedisService do
  let(:mock_redis) { instance_double(RedisClient) }

  before do
    allow(described_class).to receive(:with_redis).and_yield(mock_redis)
  end

  describe ".get and .set" do
    it "stores and retrieves a value" do
      expect(mock_redis).to receive(:call).with("SET", "test_key", "test_value").and_return("OK")
      expect(mock_redis).to receive(:call).with("GET", "test_key").and_return("test_value")

      described_class.set("test_key", "test_value")
      expect(described_class.get("test_key")).to eq("test_value")
    end
  end

  describe ".delete" do
    it "removes a key" do
      expect(mock_redis).to receive(:call).with("DEL", "test_key").and_return(1)

      described_class.delete("test_key")
    end
  end

  describe ".exists?" do
    it "checks if a key exists" do
      expect(mock_redis).to receive(:call).with("EXISTS", "test_key").and_return(1)

      expect(described_class.exists?("test_key")).to be true
    end
  end

  describe ".increment" do
    it "increments a counter" do
      expect(mock_redis).to receive(:call).with("INCRBY", "counter", 2).and_return(3)

      expect(described_class.increment("counter", by: 2)).to eq(3)
    end
  end

  describe ".add_to_set and .members_of_set" do
    it "adds and retrieves members from a set" do
      expect(mock_redis).to receive(:call).with("SADD", "test_set", "member1").and_return(1)
      expect(mock_redis).to receive(:call).with("SMEMBERS", "test_set").and_return(["member1", "member2"])

      described_class.add_to_set("test_set", "member1")
      expect(described_class.members_of_set("test_set")).to contain_exactly("member1", "member2")
    end
  end

  describe ".add_to_sorted_set and .range_from_sorted_set" do
    it "adds and retrieves members from a sorted set" do
      expect(mock_redis).to receive(:call).with("ZADD", "test_sorted_set", 10, "item1").and_return(1)
      expect(mock_redis).to receive(:call).with("ZRANGE", "test_sorted_set", 0, -1).and_return(["item1", "item2"])

      described_class.add_to_sorted_set("test_sorted_set", 10, "item1")
      expect(described_class.range_from_sorted_set("test_sorted_set", 0, -1)).to eq(["item1", "item2"])
    end
  end

  describe ".reverse_range_from_sorted_set" do
    it "retrieves a reverse range from a sorted set" do
      expect(mock_redis).to receive(:call).with("ZREVRANGE", "test_sorted_set", 0, 2).and_return(["item3", "item2", "item1"])

      result = described_class.reverse_range_from_sorted_set("test_sorted_set", 0, 2)
      expect(result).to eq(["item3", "item2", "item1"])
    end
  end

  describe ".push_to_list and .pop_from_list" do
    it "pushes and pops from a list" do
      expect(mock_redis).to receive(:call).with("RPUSH", "test_list", "value1").and_return(1)
      expect(mock_redis).to receive(:call).with("LPOP", "test_list").and_return("value1")

      described_class.push_to_list("test_list", "value1")
      expect(described_class.pop_from_list("test_list")).to eq("value1")
    end
  end

  describe ".list_range" do
    it "retrieves a range of values from a list" do
      expect(mock_redis).to receive(:call).with("LRANGE", "test_list", 0, 2).and_return(["item1", "item2", "item3"])

      expect(described_class.list_range("test_list", 0, 2)).to eq(["item1", "item2", "item3"])
    end
  end

  describe ".set_hash_field, .get_hash_field, and .get_hash_all" do
    it "stores and retrieves hash fields" do
      expect(mock_redis).to receive(:call).with("HSET", "test_hash", "field1", "value1").and_return(1)
      expect(mock_redis).to receive(:call).with("HGET", "test_hash", "field1").and_return("value1")
      expect(mock_redis).to receive(:call).with("HGETALL", "test_hash").and_return(["field1", "value1", "field2", "value2"])

      described_class.set_hash_field("test_hash", "field1", "value1")
      expect(described_class.get_hash_field("test_hash", "field1")).to eq("value1")
      expect(described_class.get_hash_all("test_hash")).to eq({ "field1" => "value1", "field2" => "value2" })
    end
  end

  describe ".publish" do
    it "publishes a message to a channel" do
      expect(mock_redis).to receive(:call).with("PUBLISH", "test_channel", "hello").and_return(1)

      described_class.publish("test_channel", "hello")
    end
  end

  describe ".eval_script" do
    it "executes a Lua script" do
      expect(mock_redis).to receive(:call).with("EVAL", "return redis.call('SET', KEYS[1], ARGV[1])", 1, "test_key", "test_value").and_return("OK")

      result = described_class.eval_script("return redis.call('SET', KEYS[1], ARGV[1])", ["test_key"], ["test_value"])
      expect(result).to eq("OK")
    end
  end

  describe ".clear_by_pattern" do
    it "deletes keys matching a pattern" do
      expect(mock_redis).to receive(:call).with("SCAN", "0", "MATCH", "prefix:*", "COUNT", 1000).and_return(["0", ["prefix:1", "prefix:2"]])
      expect(mock_redis).to receive(:call).with("DEL", "prefix:1", "prefix:2").and_return(2)

      described_class.clear_by_pattern("prefix:*")
    end
  end

  describe ".expire and .ttl" do
    it "sets expiration and retrieves time to live for a key" do
      expect(mock_redis).to receive(:call).with("EXPIRE", "test_key", 3600).and_return(1)
      expect(mock_redis).to receive(:call).with("TTL", "test_key").and_return(3598)

      described_class.expire("test_key", 3600)
      expect(described_class.ttl("test_key")).to eq(3598)
    end
  end
end
