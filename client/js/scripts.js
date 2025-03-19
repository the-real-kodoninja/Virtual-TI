document.getElementById('calc-form').onsubmit = async function(e) {
    e.preventDefault();
    const formData = new FormData(this);
    const response = await fetch(this.action, {
        method: 'POST',
        body: formData
    });
    const result = await response.text();
    document.getElementById('display').innerText = result; // Update display with result
};

document.getElementById('plot-form').onsubmit = async function(e) {
    e.preventDefault();
    const formData = new FormData(this);
    const response = await fetch(this.action, {
        method: 'POST',
        body: formData
    });
    const plot = await response.text();
    document.getElementById('plot').innerHTML = plot;
};

function appendToDisplay(value) {
    const display = document.getElementById('display');
    if (display.innerText === '0') {
        display.innerText = value; // Replace 0 with the first number
    } else {
        display.innerText += value; // Append the value
    }
}

function clearDisplay() {
    document.getElementById('display').innerText = '0'; // Clear the display
}