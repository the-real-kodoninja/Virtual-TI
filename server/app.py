from flask import Flask, render_template, request, jsonify, send_from_directory
import numpy as np
import matplotlib.pyplot as plt
import io
import base64
import os

# Specify the template folder as '../client'
template_folder = os.path.join(os.getcwd(), '..', 'client')
static_folder = os.path.join(template_folder)
print(f"Template folder: {template_folder}")
print(f"Static folder: {static_folder}")
print(f"Current working directory: {os.getcwd()}")
print(f"Index.html exists: {os.path.exists(os.path.join(template_folder, 'index.html'))}")

app = Flask(__name__, static_folder=static_folder, template_folder=template_folder)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/calculate', methods=['POST'])
def calculate():
    data = request.get_json()
    expression = data.get('expression', '')
    try:
        result = eval(expression)  # Caution: eval can be dangerous
        return jsonify(result=str(result))
    except Exception as e:
        return jsonify(result=str(e))

@app.route('/plot', methods=['POST'])
def plot():
    data = request.get_json()
    expression = data.get('expression', '')
    try:
        x = np.linspace(-10, 10, 400)
        y = eval(expression)  # Caution: eval can be dangerous
        plt.figure()
        plt.plot(x, y)
        plt.title(f'Plot of {expression}')
        plt.xlabel('x')
        plt.ylabel('y')
        plt.grid()

        # Save plot to a PNG in memory
        img = io.BytesIO()
        plt.savefig(img, format='png')
        img.seek(0)
        plot_url = base64.b64encode(img.getvalue()).decode()
        plt.close()
        return jsonify(plot_url=f'data:image/png;base64,{plot_url}')
    except Exception as e:
        return jsonify(result=str(e))

# Serve static files from the 'client' directory
@app.route('/css/<path:path>')
def send_css(path):
    return send_from_directory(os.path.join(template_folder, 'css'), path)

@app.route('/js/<path:path>')
def send_js(path):
    return send_from_directory(os.path.join(template_folder, 'js'), path)

if __name__ == '__main__':
    app.run(debug=True)