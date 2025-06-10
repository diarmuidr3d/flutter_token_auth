class MethodCounters {
  final Map<String, MethodCounter> _counters = {};

  MethodCounter operator [](String methodName) {
    if (!_counters.containsKey(methodName)) {
      _counters[methodName] = MethodCounter(methodName);
    }
    return _counters[methodName]!;
  }

  void clear() {
    _counters.forEach((key, value) {
      value.clear();
    });
  }
}

class MethodCounter {
  MethodCounter(this.methodName);

  final String methodName;
  int timesCalled = 0;
  List<Map<String, Object?>> params = [];

  void call(Map<String, Object?>? params) {
    timesCalled++;
    this.params.add(params ?? {});
  }

  void clear() {
    timesCalled = 0;
    params = [];
  }
}
