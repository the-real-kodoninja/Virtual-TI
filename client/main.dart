import 'dart:html';
import 'dart:convert';

void main() {
  querySelector('#calc-form')?.onSubmit.listen((event) {
    event.preventDefault();
    calculate();
  });

  querySelector('#plot-form')?.onSubmit.listen((event) {
    event.preventDefault();
    plot();
  });

  querySelectorAll('button').forEach((button) {
    button.onClick.listen((event) {
      final value = (event.target as ButtonElement).text ?? '';
      appendToDisplay(value);
    });
  });

  querySelector('#clear')?.onClick.listen((event) {
    clearDisplay();
  });
}

void appendToDisplay(String value) {
  final display = querySelector('#display') as DivElement;
  if (display.text == '0') {
    display.text = value; // Replace 0 with the first number
  } else {
    display.text = (display.text ?? '') + value; // Append the value
  }
}

void clearDisplay() {
  final display = querySelector('#display') as DivElement;
  display.text = ''; // Clear the display
}

void updateDisplay() {
  final display = querySelector('#display') as DivElement;
  if (display.text == '') {
    display.text = '0'; // Reset to 0 if empty
  }
}

void calculate() {
  final display = querySelector('#display') as DivElement;
  final expression = display.text ?? '';
  // Send the expression to the server for calculation
  HttpRequest.request(
    '/calculate',
    method: 'POST',
    requestHeaders: {'Content-Type': 'application/json'},
    sendData: jsonEncode({'expression': expression}),
  ).then((HttpRequest response) {
    final data = jsonDecode(response.responseText!);
    querySelector('#result')?.text = data['result']; // Update result
    display.text = data['result']; // Update display with result
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