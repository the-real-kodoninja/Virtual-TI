from flask import Flask, render_template, request, jsonify, send_from_directory
import numpy as np
import matplotlib.pyplot as plt
import io
import base64
import os
import re
from sympy import sympify, Symbol, sin, cos, tan, pi, E, I

# Specify the template folder as '../client'
template_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'client'))
static_folder = os.path.join(template_folder)
print(f"Template folder: {template_folder}")
print(f"Static folder: {static_folder}")
print(f"Current working directory: {os.getcwd()}")
print(f"Index.html exists: {os.path.exists(os.path.join(template_folder, 'index.html'))}")

app = Flask(__name__, static_folder=static_folder, template_folder=template_folder)

# Input validation: Allow only alphanumeric characters, basic math operators, and function names
ALLOWED_PATTERN = re.compile(r'^[a-zA-Z0-9\s+\-*/^().=,\[\]{}sin|cos|tan|pi|e|i|x]+$')

def validate_expression(expression):
    if not expression or not ALLOWED_PATTERN.match(expression):
        raise ValueError("Invalid expression: Only alphanumeric characters, basic math operators, and functions (sin, cos, tan, pi, e, i, x) are allowed.")

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/calculate', methods=['POST'])
def calculate():
    data = request.get_json()
    expression = data.get('expression', '')
    try:
        # Validate the expression
        validate_expression(expression)

        # Define allowed symbols
        x = Symbol('x')
        allowed_locals = {
            'sin': sin, 'cos': cos, 'tan': tan,
            'pi': pi, 'e': E, 'i': I, 'x': x
        }
        # Parse and evaluate the expression safely using sympy
        expr = sympify(expression, locals=allowed_locals)
        result = expr.evalf()  # Evaluate numerically
        return jsonify(result=str(result))
    except Exception as e:
        return jsonify(result=f"Error: {str(e)}")

@app.route('/plot', methods=['POST'])
def plot():
    data = request.get_json()
    expression1 = data.get('expression1', '')
    expression2 = data.get('expression2', None)
    x_min = data.get('x_min', -10.0)
    x_max = data.get('x_max', 10.0)
    step = data.get('step', 0.025)
    color1 = data.get('color1', '#ff0000')
    color2 = data.get('color2', '#0000ff')
    line_style = data.get('line_style', '-')
    try:
        # Validate the expressions
        validate_expression(expression1)
        if expression2:
            validate_expression(expression2)

        # Validate numerical inputs
        x_min = float(x_min)
        x_max = float(x_max)
        step = float(step)
        if x_min >= x_max or step <= 0:
            raise ValueError("Invalid range or step: x_min must be less than x_max, and step must be positive.")

        # Define x as a symbol for plotting
        x = Symbol('x')
        allowed_locals = {
            'sin': sin, 'cos': cos, 'tan': tan,
            'pi': pi, 'e': E, 'i': I, 'x': x
        }
        # Parse the expressions using sympy
        expr1 = sympify(expression1, locals=allowed_locals)
        expr2 = sympify(expression2, locals=allowed_locals) if expression2 else None

        # Generate x values
        x_vals = np.arange(x_min, x_max, step)
        # Evaluate the expressions for each x value
        y_vals1 = [float(expr1.subs(x, val).evalf()) for val in x_vals]
        y_vals2 = [float(expr2.subs(x, val).evalf()) for val in x_vals] if expr2 else None

        # Create the plot
        plt.figure()
        plt.plot(x_vals, y_vals1, color=color1, linestyle=line_style, label=expression1)
        if y_vals2:
            plt.plot(x_vals, y_vals2, color=color2, linestyle=line_style, label=expression2)
        plt.title('Function Plot')
        plt.xlabel('x')
        plt.ylabel('y')
        plt.grid()
        plt.legend()

        # Save plot to a PNG in memory
        img = io.BytesIO()
        plt.savefig(img, format='png')
        img.seek(0)
        plot_url = base64.b64encode(img.getvalue()).decode()
        plt.close()
        return jsonify(plot_url=f'data:image/png;base64,{plot_url}')
    except Exception as e:
        return jsonify(result=f"Error: {str(e)}")

# Serve static files from the 'client' directory
@app.route('/css/<path:path>')
def send_css(path):
    return send_from_directory(os.path.join(template_folder, 'css'), path)

@app.route('/js/<path:path>')
def send_js(path):
    return send_from_directory(os.path.join(template_folder, 'js'), path)

if __name__ == '__main__':
    app.run(debug=True)