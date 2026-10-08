const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

mongoose.connect(process.env.MONGO_URI).then(async () => {
  const hash = await bcrypt.hash('NewPassword123', 12);
  // Use native driver to bypass Mongoose schema validation
  const db = mongoose.connection.db;
  const result = await db.collection('users').updateOne(
    { email: 'tharumendis698@gmail.com' },
    { $set: { password: hash, role: 'nurse' } }
  );
  console.log('matched:', result.matchedCount, 'modified:', result.modifiedCount);
  const user = await db.collection('users').findOne({ email: 'tharumendis698@gmail.com' }, { projection: { email: 1, role: 1 } });
  console.log('role in DB now:', user?.role);
  mongoose.disconnect();
});
