const dns = require('node:dns');
dns.setServers(['1.1.1.1', '8.8.8.8']);

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./models/User');
require('dotenv').config();

async function seed() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('MongoDB connected');

  const password = await bcrypt.hash('123456', 12);

  const staff = [
    { name: 'Dr. Madusha', email: 'madusha@gmail.com', nic: 'DOC1024', phone: '0771000001', role: 'doctor',  password },
    { name: 'Admin Root',  email: 'admin@hospital.lk', nic: 'ADM2001', phone: '0771000002', role: 'admin',   password },
    { name: 'Nurse Aysha', email: 'aysha@hospital.lk', nic: 'NRS3001', phone: '0771000003', role: 'nurse',   password },
  ];

  for (const s of staff) {
    const exists = await User.findOne({ email: s.email });
    if (exists) {
      console.log(`Already exists: ${s.email}`);
    } else {
      await User.create(s);
      console.log(`Created: ${s.email} (${s.role})`);
    }
  }

  process.exit(0);
}

seed().catch((err) => { console.error(err); process.exit(1); });
