enum TaskState { initialized, searching, observing, found, notFound, completed, cancelled }

class TaskStepResult {
  final TaskState state;
  final String targetItem;
  final String instructionPrompt;

  const TaskStepResult({
    required this.state,
    required this.targetItem,
    required this.instructionPrompt,
  });
}

class TaskAssistanceEngine {
  TaskState _currentState = TaskState.initialized;
  String _targetItem = '';

  TaskState get currentState => _currentState;
  String get targetItem => _targetItem;

  TaskStepResult startTask(String query) {
    _targetItem = _extractTargetItem(query);
    _currentState = TaskState.searching;

    return TaskStepResult(
      state: _currentState,
      targetItem: _targetItem,
      instructionPrompt: 'Task started: Searching for $_targetItem. Step 1: Please point the camera towards the table or desk surface.',
    );
  }

  TaskStepResult processFrameObservations(bool objectFound, String spatialLoc) {
    if (_currentState == TaskState.searching || _currentState == TaskState.observing) {
      if (objectFound) {
        _currentState = TaskState.found;
        return TaskStepResult(
          state: _currentState,
          targetItem: _targetItem,
          instructionPrompt: 'Target acquired! Your $_targetItem is $spatialLoc. Step 2: Move your hand forward slowly.',
        );
      } else {
        _currentState = TaskState.observing;
        return TaskStepResult(
          state: _currentState,
          targetItem: _targetItem,
          instructionPrompt: 'Still scanning... Please pan your camera slightly to the right.',
        );
      }
    }

    if (_currentState == TaskState.found) {
      _currentState = TaskState.completed;
      return TaskStepResult(
        state: _currentState,
        targetItem: _targetItem,
        instructionPrompt: 'Task completed successfully. You are directly in front of your $_targetItem.',
      );
    }

    return TaskStepResult(
      state: _currentState,
      targetItem: _targetItem,
      instructionPrompt: 'Task state: ${_currentState.name}.',
    );
  }

  void cancelTask() {
    _currentState = TaskState.cancelled;
  }

  String _extractTargetItem(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('keys')) return 'keys';
    if (lower.contains('phone')) return 'phone';
    if (lower.contains('bottle')) return 'water bottle';
    if (lower.contains('medicine')) return 'medicine bottle';
    if (lower.contains('glasses')) return 'glasses';
    return 'item';
  }
}
