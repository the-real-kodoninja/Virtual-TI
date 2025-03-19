# 🖥️ Virtual-TI: Your Web-Based TI Graphing Calculator Emulator 🚀

## 🌟 Overview

**Virtual-TI** brings the power of a TI graphing calculator to your web browser! 🌐 Perform basic arithmetic, plot complex mathematical functions, and experience a user-friendly interface that mimics the classic TI calculator. Whether you're a student, educator, or math enthusiast, Virtual-TI is your go-to tool for on-the-fly calculations and visualizations.

## ✨ Features

* **➕ Basic Calculations:** Effortlessly perform arithmetic operations (addition, subtraction, multiplication, division) with the precision you expect.
* **📈 Dynamic Graphing:** Plot mathematical functions using an intuitive input format and watch your equations come to life visually.
* **🖱️ Interactive Interface:** Enjoy a seamless web-based experience with real-time expression input and result display.
* **🎨 Customizable Graphs:** Adjust graph parameters and visual styles.
* **📍 Sticky Widget:** A draggable calculator widget that can be minimized into a small circle at the bottom of your screen, making it accessible on any page.
* **📱 Touch Support:** Use the calculator on mobile devices with touch-based dragging and interaction.
* **💾 Persistent State:** The calculator’s position and state (minimized or expanded) are saved across page reloads using `localStorage`.
* **📖 Introductory Guide:** A welcome screen explains how to use the calculator before you start, which hides when the calculator is expanded.

## 🛠️ Technologies Used

* **🐍 Python (Flask):** The robust backend is powered by Flask, ensuring speed and reliability.
* **🔢 NumPy:** Numerical operations and array handling are made efficient with the power of NumPy.
* **📊 Matplotlib:** Visualize your mathematical functions with high-quality graphs using Matplotlib.
* **🌐 HTML/CSS:** The user interface is built with standard web technologies for broad compatibility.
* **💅 SASS:** Maintainable and modular styles are achieved with the help of SASS.
* **🎯 Dart:** Front-end logic is handled using Dart for a seamless user experience.

## 🚀 Installation Instructions

1. **Clone the Repository:**

    ```bash
    git clone <repository-url>
    cd Virtual-TI
    ```

2. **Run the Setup Script:**

    The `setup.sh` script will install the necessary dependencies and set up your environment. Run the following command:

    ```bash
    ./setup.sh
    ```

3. **Activate the Virtual Environment:**

    If the virtual environment was created, activate it:

    ```bash
    source venv/bin/activate  # On macOS/Linux
    venv\Scripts\activate  # On Windows
    ```

4. **Compile Dart to JavaScript:**

    If the setup script did not compile the Dart code, you can manually compile it:

    ```bash
    dart compile js -o client/js/main.dart.js client/main.dart
    ```

5. **Run the Application:**

    Navigate to the `server` directory and run the application:

    ```bash
    cd server
    python app.py
    ```

6. **Access Virtual-TI:**

    Open your web browser and navigate to `http://localhost:5000` to access the Virtual-TI calculator emulator.

## 🤝 Contributing

We welcome contributions! Please feel free to submit pull requests or open issues to help improve Virtual-TI.

## 📜 License

This project is licensed under the MIT License - see the `LICENSE` file for details.

## 🙏 Acknowledgments

* Thank you to the creators and maintainers of Python, Flask, NumPy, Matplotlib, HTML, CSS, SASS, and Dart.
* Built with passion by Emmanuel Barry Moore.

#### Changes to `README.md`
- **New Features**: Added sections for the sticky widget, touch support, persistent state, and introductory guide.
- **Usage Section**: Added a detailed usage guide explaining how to interact with the calculator, including the new features.
- **Security Note**: Added a warning about the use of `eval` in `app.py` and suggested using `sympy` as a safer alternative.

---

### Reviewing and Securing `app.py`

Your `app.py` uses `eval` to evaluate expressions, which is a significant security risk because it can execute arbitrary Python code. For example, a malicious user could send an expression like `__import__('os').system('rm -rf /')`, which could delete files on your server. Let’s replace `eval` with a safer alternative using `sympy` for symbolic mathematics.

#### Updated `server/app.py`

First, ensure `sympy` is installed by adding it to your `server/requirements.txt`: