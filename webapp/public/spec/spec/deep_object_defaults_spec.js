describe("DeepObjectDefaults", function() {
  it("merges shallow objecs correctly", function() {
    var defaults = {
      key1: "default1",
      key2: "default2"
    };

    var data = {
      key1: "data1",
      key3: "data3"
    };

    var result = DeepObjectDefaults.merge(data, defaults);

    expect(result).toEqual({
      key1: "data1",
      key2: "default2",
      key3: "data3"
    });
  });

  it("merges deep objects correctly", function() {
    var defaults = {
      key1: "default1",
      key2: {
        subkey1: "default_sub1",
        subkey2: "default_sub2"
      }
    };

    var data = {
      key1: "data1",
      key2: {
        subkey2: "data_sub2"
      }
    };

    var result = DeepObjectDefaults.merge(data, defaults);

    expect(result).toEqual({
      key1: "data1",
      key2: {
        subkey1: "default_sub1",
        subkey2: "data_sub2"
      }
    });
  });
});

