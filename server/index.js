require('dotenv').config();
const express = require('express');
const cors = require('cors');
require('./db'); // creates tables + seeds demo data

const app = express();
app.use(cors());
app.use(express.json());

app.get('/', (req, res) => res.json({ service: 'Government Hospital OPD API', status: 'ok' }));
app.use('/api/auth', require('./routes/auth'));
app.use('/api/clinics', require('./routes/clinics'));
app.use('/api/sessions', require('./routes/sessions'));
app.use('/api/appointments', require('./routes/appointments'));
app.use('/api/patients', require('./routes/patients'));

app.use((req, res) => res.status(404).json({ error: 'Route not found.' }));
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Something went wrong on the server.' });
});

const PORT = process.env.PORT || 3000;
if (require.main === module) {
  app.listen(PORT, () => console.log(`OPD API running on http://localhost:${PORT}`));
}
module.exports = app;
