import 'dart:html';
import 'dart:convert';
import 'dart:math' show max, min;

void main() {
  // Load saved position and state from localStorage
  loadSavedState();

  // Bind click event for the toggle button (minimized calculator)
  querySelector('.toggle-button')?.onClick.listen((event) {
    toggleCalculator();
  });

  // Bind click event for the close button (expanded calculator)
  querySelector('.close-button')?.onClick.listen((event) {
    toggleCalculator();
  });

  // Form submissions
  querySelector('#calc-form')?.onSubmit.listen((event) {
    event.preventDefault();
    calculate();
  });

  querySelector('#plot-form')?.onSubmit.listen((event) {
    event.preventDefault();
    submitPlot();
  });

  // Keypad buttons (excluding special buttons)
  querySelectorAll('.keypad button').forEach((button) {
    final id = button.id;
    if (id == 'nav-up' || id == 'nav-down' || id == 'nav-left' || id == 'nav-right' || id == 'nav-enter' ||
        id == 'func-doc' || id == 'func-menu' || id == 'func-on' || id == 'func-esc' ||
        id == 'show-vars' || id == 'clear' || id == 'func-sin' || id == 'func-cos' || id == 'func-tan' ||
        id == 'show-history' || id == 'show-plot-modal') {
      return; // Skip special buttons, handled below
    }
    button.onClick.listen((event) {
      final value = (button as ButtonElement).text ?? '';
      appendToDisplay(value);
    });
  });

  // Navigation buttons
  querySelector('#nav-up')?.onClick.listen((event) => navigate('up'));
  querySelector('#nav-down')?.onClick.listen((event) => navigate('down'));
  querySelector('#nav-left')?.onClick.listen((event) => navigate('left'));
  querySelector('#nav-right')?.onClick.listen((event) => navigate('right'));
  querySelector('#nav-enter')?.onClick.listen((event) => navigate('enter'));

  // Function buttons
  querySelector('#func-doc')?.onClick.listen((event) => performFunction('doc'));
  querySelector('#func-menu')?.onClick.listen((event) => performFunction('menu'));
  querySelector('#func-on')?.onClick.listen((event) => performFunction('on'));
  querySelector('#func-esc')?.onClick.listen((event) => performFunction('esc'));

  // Math function buttons
  querySelector('#func-sin')?.onClick.listen((event) => appendToDisplay('sin('));
  querySelector('#func-cos')?.onClick.listen((event) => appendToDisplay('cos('));
  querySelector('#func-tan')?.onClick.listen((event) => appendToDisplay('tan('));

  // Clear button
  querySelector('#clear')?.onClick.listen((event) {
    clearDisplay();
  });

  // Modal buttons
  querySelector('#show-plot-modal')?.onClick.listen((event) {
    showPlotModal();
  });

  querySelector('#submit-plot')?.onClick.listen((event) {
    submitPlot();
  });

  querySelector('#close-plot-modal')?.onClick.listen((event) {
    closePlotModal();
  });

  querySelector('#show-history')?.onClick.listen((event) {
    showHistory();
  });

  querySelector('#close-history-modal')?.onClick.listen((event) {
    closeHistoryModal();
  });

  querySelector('#show-vars')?.onClick.listen((event) {
    showVars();
  });

  querySelector('#close-vars-modal')?.onClick.listen((event) {
    closeVarsModal();
  });

  // Handle keyboard input for navigation
  document.onKeyDown.listen((event) {
    switch (event.key) {
      case 'ArrowUp':
        navigate('up');
        break;
      case 'ArrowDown':
        navigate('down');
        break;
      case 'ArrowLeft':
        navigate('left');
        break;
      case 'ArrowRight':
        navigate('right');
        break;
      case 'Enter':
        navigate('enter');
        break;
    }
  });

  // Make the calculator draggable (mouse and touch support)
  makeDraggable();
}

List<String> calculationHistory = [];
int historyIndex = -1;
Map<String, double> variables = {};

void appendToDisplay(String value) {
  final display = querySelector('#display') as DivElement;
  final currentText = display.text ?? '';
  display.text = currentText + value;

  // Scroll to the end of the display
  display.scrollLeft = display.scrollWidth;
}

void clearDisplay() {
  final display = querySelector('#display') as DivElement;
  display.text = '';
}

void navigate(String direction) {
  final display = querySelector('#display') as DivElement;
  switch (direction) {
    case 'up':
      if (calculationHistory.isEmpty) return;
      if (historyIndex == -1) historyIndex = calculationHistory.length - 1;
      else if (historyIndex > 0) historyIndex--;
      display.text = calculationHistory[historyIndex];
      break;
    case 'down':
      if (calculationHistory.isEmpty) return;
      if (historyIndex == calculationHistory.length - 1) {
        historyIndex = -1;
        display.text = '';
      } else if (historyIndex >= 0) {
        historyIndex++;
        display.text = calculationHistory[historyIndex];
      }
      break;
    case 'left':
      display.scrollLeft -= 20;
      break;
    case 'right':
      display.scrollLeft += 20;
      break;
    case 'enter':
      calculate();
      break;
  }
}

void performFunction(String func) {
  switch (func) {
    case 'doc':
      querySelector('#result')?.text = 'Documentation not implemented';
      break;
    case 'menu':
      querySelector('#result')?.text = 'Menu not implemented';
      break;
    case 'on':
      clearDisplay();
      querySelector('#result')?.text = '';
      querySelector('#plot')?.innerHtml = '';
      calculationHistory.clear();
      historyIndex = -1;
      variables.clear();
      break;
    case 'esc':
      clearDisplay();
      break;
  }
}

void calculate() {
  final display = querySelector('#display') as DivElement;
  final expression = display.text ?? '';
  if (expression.isEmpty) return;

  // Store the expression in history
  calculationHistory.add(expression);
  historyIndex = -1;

  // Replace variables in the expression
  String evalExpression = expression;
  for (var entry in variables.entries) {
    evalExpression = evalExpression.replaceAll(entry.key, entry.value.toString());
  }

  // Generate explanation for the expression
  explainExpression(expression);

  final calcInput = querySelector('#calc-expression') as InputElement;
  calcInput.value = evalExpression;

  HttpRequest.request(
    '/calculate',
    method: 'POST',
    requestHeaders: {'Content-Type': 'application/json'},
    sendData: jsonEncode({'expression': evalExpression}),
  ).then((HttpRequest response) {
    final data = jsonDecode(response.responseText!);
    final result = data['result'] ?? 'Error';
    querySelector('#result')?.text = result;
    display.text = result;

    // Check if the expression is a variable assignment (e.g., "A=5")
    if (expression.contains('=')) {
      final parts = expression.split('=');
      if (parts.length == 2) {
        final varName = parts[0].trim();
        final varValue = double.tryParse(result);
        if (varName.isNotEmpty && varValue != null) {
          variables[varName] = varValue;
        }
      }
    }
  }).catchError((error) {
    querySelector('#result')?.text = 'Calculation error';
  });
}

void explainExpression(String expression) {
  final explanationDiv = querySelector('#explanation') as DivElement;
  String explanation = 'Explanation of "$expression":\n';

  // Simulate AI-like explanation with rule-based logic
  if (expression.contains('+')) {
    final parts = expression.split('+');
    explanation += 'This expression adds two numbers: ${parts[0].trim()} and ${parts[1].trim()}. Addition combines the values to produce a sum.';
  } else if (expression.contains('−') || expression.contains('-')) {
    final parts = expression.split(RegExp(r'−|-'));
    explanation += 'This expression subtracts ${parts[1].trim()} from ${parts[0].trim()}. Subtraction finds the difference between the two numbers.';
  } else if (expression.contains('×')) {
    final parts = expression.split('×');
    explanation += 'This expression multiplies ${parts[0].trim()} by ${parts[1].trim()}. Multiplication finds the product of the two numbers.';
  } else if (expression.contains('sin(')) {
    final funcContent = expression.substring(expression.indexOf('(') + 1, expression.lastIndexOf(')'));
    explanation += 'This expression calculates the sine of ${funcContent} radians. The sine function returns the ratio of the opposite side to the hypotenuse in a right triangle, often used in trigonometry to model periodic phenomena.';
  } else if (expression.contains('cos(')) {
    final funcContent = expression.substring(expression.indexOf('(') + 1, expression.lastIndexOf(')'));
    explanation += 'This expression calculates the cosine of ${funcContent} radians. The cosine function returns the ratio of the adjacent side to the hypotenuse in a right triangle, commonly used in wave analysis and geometry.';
  } else if (expression.contains('tan(')) {
    final funcContent = expression.substring(expression.indexOf('(') + 1, expression.lastIndexOf(')'));
    explanation += 'This expression calculates the tangent of ${funcContent} radians. The tangent function is the ratio of sine to cosine, often used in trigonometry to find angles and slopes.';
  } else if (expression.contains('=')) {
    final parts = expression.split('=');
    explanation += 'This expression assigns the value ${parts[1].trim()} to the variable ${parts[0].trim()}. Variable assignment stores a value for later use in calculations.';
  } else {
    explanation += 'This expression appears to be a single value or an unrecognized operation. Please enter a mathematical expression like "2+3" or "sin(0.5)" to get a detailed explanation.';
  }

  explanationDiv.text = explanation;
  // Scroll to the bottom of the explanation div
  explanationDiv.scrollTop = explanationDiv.scrollHeight;
}

void showPlotModal() {
  final modal = querySelector('#plot-modal') as DivElement;
  final expr1Input = querySelector('#plot-expr1') as InputElement;
  expr1Input.value = (querySelector('#display') as DivElement).text ?? '';
  modal.classes.add('active');
}

void closePlotModal() {
  final modal = querySelector('#plot-modal') as DivElement;
  modal.classes.remove('active');
}

void submitPlot() {
  final expr1 = (querySelector('#plot-expr1') as InputElement).value ?? '';
  final expr2 = (querySelector('#plot-expr2') as InputElement).value ?? '';
  final xMin = double.tryParse((querySelector('#x-min') as InputElement).value ?? '-10') ?? -10.0;
  final xMax = double.tryParse((querySelector('#x-max') as InputElement).value ?? '10') ?? 10.0;
  final step = double.tryParse((querySelector('#step') as InputElement).value ?? '0.025') ?? 0.025;
  final color1 = (querySelector('#color1') as InputElement).value ?? '#ff0000';
  final color2 = (querySelector('#color2') as InputElement).value ?? '#0000ff';
  final lineStyle = (querySelector('#line-style') as SelectElement).value ?? '-';

  if (expr1.isEmpty) {
    querySelector('#plot')?.text = 'Error: At least one expression is required';
    closePlotModal();
    return;
  }

  // Replace variables in the expressions
  String evalExpr1 = expr1;
  String? evalExpr2 = expr2.isNotEmpty ? expr2 : null;
  for (var entry in variables.entries) {
    evalExpr1 = evalExpr1.replaceAll(entry.key, entry.value.toString());
    if (evalExpr2 != null) {
      evalExpr2 = evalExpr2.replaceAll(entry.key, entry.value.toString());
    }
  }

  HttpRequest.request(
    '/plot',
    method: 'POST',
    requestHeaders: {'Content-Type': 'application/json'},
    sendData: jsonEncode({
      'expression1': evalExpr1,
      'expression2': evalExpr2,
      'x_min': xMin,
      'x_max': xMax,
      'step': step,
      'color1': color1,
      'color2': color2,
      'line_style': lineStyle,
    }),
  ).then((HttpRequest response) {
    final data = jsonDecode(response.responseText!);
    if (data['plot_url'] != null) {
      querySelector('#plot')?.innerHtml = '<img src="${data['plot_url']}" />';
    } else {
      querySelector('#plot')?.text = 'Error: ${data['result'] ?? 'Plotting failed'}';
    }
    closePlotModal();
  }).catchError((error) {
    querySelector('#plot')?.text = 'Plotting error';
    closePlotModal();
  });
}

void showHistory() {
  final modal = querySelector('#history-modal') as DivElement;
  final historyList = querySelector('#history-list') as UListElement;
  historyList.innerHtml = '';
  for (var expr in calculationHistory.reversed) {
    final li = LIElement()..text = expr;
    historyList.append(li);
  }
  modal.classes.add('active');
}

void closeHistoryModal() {
  final modal = querySelector('#history-modal') as DivElement;
  modal.classes.remove('active');
}

void showVars() {
  final modal = querySelector('#vars-modal') as DivElement;
  final varsList = querySelector('#vars-list') as UListElement;
  varsList.innerHtml = '';
  for (var entry in variables.entries) {
    final li = LIElement()..text = '${entry.key} = ${entry.value}';
    varsList.append(li);
  }
  modal.classes.add('active');
}

void closeVarsModal() {
  final modal = querySelector('#vars-modal') as DivElement;
  modal.classes.remove('active');
}

void toggleCalculator() {
  final calculator = querySelector('#calculator') as DivElement;
  final minimized = querySelector('#calculator-minimized') as DivElement;

  if (calculator.classes.contains('active')) {
    calculator.classes.remove('active');
    minimized.style.display = 'flex';
    // Save state
    window.localStorage['calculatorState'] = 'minimized';
  } else {
    calculator.classes.add('active');
    minimized.style.display = 'none';
    // Save state
    window.localStorage['calculatorState'] = 'expanded';
  }
}

void loadSavedState() {
  final calculator = querySelector('#calculator') as DivElement;
  final minimized = querySelector('#calculator-minimized') as DivElement;
  final widget = querySelector('#calculator-widget') as DivElement;

  // Load calculator state
  final state = window.localStorage['calculatorState'];
  if (state == 'expanded') {
    calculator.classes.add('active');
    minimized.style.display = 'none';
  } else {
    calculator.classes.remove('active');
    minimized.style.display = 'flex';
  }

  // Load position, default to top-right if not set
  final savedTop = window.localStorage['calculatorTop'] ?? '20px'; // Default to 20px from top
  final savedLeft = window.localStorage['calculatorLeft'] ?? 'auto';
  widget.style.top = savedTop;
  widget.style.left = savedLeft;
  widget.style.bottom = 'auto';
  widget.style.right = '20px'; // Ensure it aligns with CSS
}

void makeDraggable() {
  final widget = querySelector('#calculator-widget') as DivElement;
  double pos1 = 0, pos2 = 0, pos3 = 0, pos4 = 0;
  var isDragging = false;

  // Mouse events
  widget.onMouseDown.listen((event) {
    event.preventDefault();
    pos3 = event.page.x.toDouble();
    pos4 = event.page.y.toDouble();
    isDragging = true;

    document.onMouseMove.listen((event) {
      if (!isDragging) return;
      event.preventDefault();
      pos1 = pos3 - event.page.x.toDouble();
      pos2 = pos4 - event.page.y.toDouble();
      pos3 = event.page.x.toDouble();
      pos4 = event.page.y.toDouble();

      var newTop = widget.offsetTop - pos2;
      var newLeft = widget.offsetLeft - pos1;

      // Boundary checks
      newTop = max(20.0, min(newTop, (window.innerHeight! - widget.offsetHeight - 20).toDouble())); // Keep 20px from top and bottom
      newLeft = max(0.0, min(newLeft, (window.innerWidth! - widget.offsetWidth - 20).toDouble())); // Keep 20px from right

      widget.style.top = '${newTop}px';
      widget.style.left = '${newLeft}px';
      widget.style.bottom = 'auto';
      widget.style.right = 'auto';

      // Save position to localStorage
      window.localStorage['calculatorTop'] = '${newTop}px';
      window.localStorage['calculatorLeft'] = '${newLeft}px';
    });

    document.onMouseUp.listen((event) {
      isDragging = false;
    });
  });

  // Touch events for mobile support
  widget.onTouchStart.listen((event) {
    event.preventDefault();
    final touches = event.touches;
    if (touches == null || touches.isEmpty) {
      print('No touches detected on touchstart');
      return;
    }
    final touch = touches[0];
    pos3 = touch.client.x.toDouble() + window.scrollX.toDouble();
    pos4 = touch.client.y.toDouble() + window.scrollY.toDouble();
    isDragging = true;
    print('Touch start: clientX=${touch.client.x}, clientY=${touch.client.y}, scrollX=${window.scrollX}, scrollY=${window.scrollY}');
  });

  document.onTouchMove.listen((event) {
    if (!isDragging) return;
    event.preventDefault();
    final touches = event.touches;
    if (touches == null || touches.isEmpty) {
      print('No touches detected on touchmove');
      return;
    }
    final touch = touches[0];
    final currentX = touch.client.x.toDouble() + window.scrollX.toDouble();
    final currentY = touch.client.y.toDouble() + window.scrollY.toDouble();
    pos1 = pos3 - currentX;
    pos2 = pos4 - currentY;
    pos3 = currentX;
    pos4 = currentY;
    print('Touch move: clientX=${touch.client.x}, clientY=${touch.client.y}, scrollX=${window.scrollX}, scrollY=${window.scrollY}');

    var newTop = widget.offsetTop - pos2;
    var newLeft = widget.offsetLeft - pos1;

    // Boundary checks
    newTop = max(20.0, min(newTop, (window.innerHeight! - widget.offsetHeight - 20).toDouble())); // Keep 20px from top and bottom
    newLeft = max(0.0, min(newLeft, (window.innerWidth! - widget.offsetWidth - 20).toDouble())); // Keep 20px from right

    widget.style.top = '${newTop}px';
    widget.style.left = '${newLeft}px';
    widget.style.bottom = 'auto';
    widget.style.right = 'auto';

    // Save position to localStorage
    window.localStorage['calculatorTop'] = '${newTop}px';
    window.localStorage['calculatorLeft'] = '${newLeft}px';
  });

  document.onTouchEnd.listen((event) {
    isDragging = false;
    print('Touch end');
  });
}