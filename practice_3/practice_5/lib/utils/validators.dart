class AppValidators {
  const AppValidators._();

  static String? requiredText(
    String? value, {
    String fieldName = 'Поле',
  }) {
    if (value == null ||
        value.trim().isEmpty) {
      return '$fieldName обязательно для заполнения';
    }

    return null;
  }

  static String? requiredWithMaxLength(
    String? value, {
    required String fieldName,
    required int maxLength,
  }) {
    final requiredError = requiredText(
      value,
      fieldName: fieldName,
    );

    if (requiredError != null) {
      return requiredError;
    }

    if (value!.trim().length > maxLength) {
      return '$fieldName: максимум '
          '$maxLength символов';
    }

    return null;
  }

  static String? integerInRange(
    String? value, {
    required String fieldName,
    required int min,
    required int max,
  }) {
    final requiredError = requiredText(
      value,
      fieldName: fieldName,
    );

    if (requiredError != null) {
      return requiredError;
    }

    final number =
        int.tryParse(value!.trim());

    if (number == null) {
      return '$fieldName должен быть целым числом';
    }

    if (number < min ||
        number > max) {
      return '$fieldName должен быть '
          'от $min до $max';
    }

    return null;
  }

  static String? positiveInteger(
    String? value, {
    String fieldName = 'Значение',
  }) {
    final requiredError = requiredText(
      value,
      fieldName: fieldName,
    );

    if (requiredError != null) {
      return requiredError;
    }

    final number =
        int.tryParse(value!.trim());

    if (number == null) {
      return '$fieldName должен быть целым числом';
    }

    if (number <= 0) {
      return '$fieldName должен быть больше 0';
    }

    return null;
  }

  static String? nonNegativeInteger(
    String? value, {
    String fieldName = 'Значение',
  }) {
    final requiredError = requiredText(
      value,
      fieldName: fieldName,
    );

    if (requiredError != null) {
      return requiredError;
    }

    final number =
        int.tryParse(value!.trim());

    if (number == null) {
      return '$fieldName должен быть целым числом';
    }

    if (number < 0) {
      return '$fieldName не может быть отрицательным';
    }

    return null;
  }

  static String? email(
    String? value, {
    String fieldName = 'Email',
  }) {
    final requiredError = requiredText(
      value,
      fieldName: fieldName,
    );

    if (requiredError != null) {
      return requiredError;
    }

    final text = value!.trim();

    final expression = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!expression.hasMatch(text)) {
      return 'Введите корректный email';
    }

    return null;
  }
}