import 'dart:html';
import 'dart:convert';
import 'dart:math' show max, min;

void main() {
  // Load saved position and state from localStorage
  loadSavedState();

  querySelector('#calc-form')?.onSubmit.listen((event) {
    event.preventDefault();
    calculate();
  });

  querySelector('#plot-form')?.onSubmit.listen((event) {
    event.preventDefault();
    plot();
  });

  querySelectorAll('.keypad button').forEach((button) {
    button.onClick.listen((event) {
      final value = (event.target as ButtonElement).text ?? '';
      if (value != 'Enter' && value != 'Doc' && value != 'Menu' && value != 'On' && value != 'Esc' && value != 'Plot' && value != 'Hist' && value != 'Vars') {
        appendToDisplay(value);
      }
    });
  });

  querySelector('#clear')?.onClick.listen((event) {
    clearDisplay();
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

void plot() {
  final display = querySelector('#display') as DivElement;
  final expression = display.text ?? '';
  // Send the expression to the server for plotting
  HttpRequest.request(
    '/plot',
    method: 'POST',
    requestHeaders: {'Content-Type': 'application/json'},
    sendData: jsonEncode({'expression': expression}),
  ).then((HttpRequest response) {
    final data = jsonDecode(response.responseText!);
    if (data['plot_url'] != null) {
      querySelector('#plot')?.innerHtml = '<img src="${data['plot_url']}" />'; // Update plot
    } else {
      querySelector('#plot')?.text = data['result']; // Show error message
    }
  });
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
  final intro = querySelector('#intro') as DivElement;

  if (calculator.classes.contains('active')) {
    calculator.classes.remove('active');
    minimized.style.display = 'flex';
    intro.classes.remove('hidden');
    // Save state
    window.localStorage['calculatorState'] = 'minimized';
  } else {
    calculator.classes.add('active');
    minimized.style.display = 'none';
    intro.classes.add('hidden');
    // Save state
    window.localStorage['calculatorState'] = 'expanded';
  }
}

void loadSavedState() {
  final calculator = querySelector('#calculator') as DivElement;
  final minimized = querySelector('#calculator-minimized') as DivElement;
  final intro = querySelector('#intro') as DivElement;
  final widget = querySelector('#calculator-widget') as DivElement;

  // Load calculator state
  final state = window.localStorage['calculatorState'];
  if (state == 'expanded') {
    calculator.classes.add('active');
    minimized.style.display = 'none';
    intro.classes.add('hidden');
  } else {
    calculator.classes.remove('active');
    minimized.style.display = 'flex';
    intro.classes.remove('hidden');
  }

  // Load position
  final savedTop = window.localStorage['calculatorTop'];
  final savedLeft = window.localStorage['calculatorLeft'];
  if (savedTop != null && savedLeft != null) {
    widget.style.top = savedTop;
    widget.style.left = savedLeft;
    widget.style.bottom = 'auto';
    widget.style.right = 'auto';
  }
}

void makeDraggable() {
  final widget = querySelector('#calculator-widget') as DivElement;
  double pos1 = 0, pos2 = 0, pos3 = 0, pos4 = 0;
  var isDragging = false;

  // Mouse events
  widget.onMouseDown.listen((event) {
    event.preventDefault();
    pos3 = event.client.x.toDouble();
    pos4 = event.client.y.toDouble();
    isDragging = true;

    document.onMouseMove.listen((event) {
      if (!isDragging) return;
      event.preventDefault();
      pos1 = pos3 - event.client.x.toDouble();
      pos2 = pos4 - event.client.y.toDouble();
      pos3 = event.client.x.toDouble();
      pos4 = event.client.y.toDouble();

      var newTop = widget.offsetTop - pos2;
      var newLeft = widget.offsetLeft - pos1;

      // Boundary checks
      newTop = max(0.0, min(newTop, (window.innerHeight! - widget.offsetHeight).toDouble()));
      newLeft = max(0.0, min(newLeft, (window.innerWidth! - widget.offsetWidth).toDouble()));

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
    if (touches == null || touches.isEmpty) return;
    final touch = touches[0];
    pos3 = touch.client.x.toDouble();
    pos4 = touch.client.y.toDouble();
    isDragging = true;

    document.onTouchMove.listen((event) {
      if (!isDragging) return;
      event.preventDefault();
      final touches = event.touches;
      if (touches == null || touches.isEmpty) return;
      final touch = touches[0];
      pos1 = pos3 - touch.client.x.toDouble();
      pos2 = pos4 - touch.client.y.toDouble();
      pos3 = touch.client.x.toDouble();
      pos4 = touch.client.y.toDouble();

      var newTop = widget.offsetTop - pos2;
      var newLeft = widget.offsetLeft - pos1;

      // Boundary checks
      newTop = max(0.0, min(newTop, (window.innerHeight! - widget.offsetHeight).toDouble()));
      newLeft = max(0.0, min(newLeft, (window.innerWidth! - widget.offsetWidth).toDouble()));

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
    });
  });
}