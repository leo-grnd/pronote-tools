const express = require('express');
const bodyParser = require('body-parser');
const { execFile } = require('child_process');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 5000;

app.use(bodyParser.json());

// POST /login expects username, password and ent key
app.post('/login', (req, res) => {
  const { username, password, ent } = req.body;
  const script = path.join(__dirname, '..', 'all-scripts', 'get_grades.py');
  const args = [username, password, ent];

  execFile('python3', [script, ...args], (error, stdout, stderr) => {
    if (error) {
      console.error('Python error', error);
      return res.status(500).json({ error: 'Login failed' });
    }
    // For demo, return success with a dummy token
    return res.json({ token: 'demo-token' });
  });
});

app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
