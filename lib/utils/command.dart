import 'package:flutter/foundation.dart';

sealed class Result<T> {
  const Result();

  static Ok<T> ok<T>(T value) => Ok(value);
  static Error<T> error<T>(Exception e) => Error(e);
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Error<T> extends Result<T> {
  const Error(this.exception);
  final Exception exception;
}

/// A command that takes no arguments.
class Command0<T> extends ChangeNotifier {
  Command0(this._action);

  final Future<Result<T>> Function() _action;
  bool _running = false;
  Result<T>? _result;

  bool get running => _running;
  Result<T>? get result => _result;

  Future<void> execute() async {
    if (_running) return;
    _running = true;
    _result = null;
    notifyListeners();
    _result = await _action();
    _running = false;
    notifyListeners();
  }
}

/// A command that takes one argument.
class Command1<A, T> extends ChangeNotifier {
  Command1(this._action);

  final Future<Result<T>> Function(A) _action;
  bool _running = false;
  Result<T>? _result;

  bool get running => _running;
  Result<T>? get result => _result;

  Future<void> execute(A argument) async {
    if (_running) return;
    _running = true;
    _result = null;
    notifyListeners();
    _result = await _action(argument);
    _running = false;
    notifyListeners();
  }
}
