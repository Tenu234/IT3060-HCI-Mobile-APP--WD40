const dns = require('node:dns');
dns.setServers(['1.1.1.1', '8.8.8.8']);

const mongoose = require('mongoose');
const User = require('./models/User');
const Appointment = require('./models/Appointment');
require('dotenv').config();

async function seed() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('MongoDB connected');

  // Find praboda's account
  const patient = await User.findOne({ name: /praboda/i });
  if (!patient) {
    console.log('User "praboda" not found. Make sure you registered first.');
    process.exit(1);
  }

  console.log('Found user:', patient.name, patient._id);

  // Delete old seeded appointments for this user
  await Appointment.deleteMany({ patientId: patient._id });

  // Create 2 appointments
  await Appointment.insertMany([
    {
      patientId: patient._id,
      hospitalName: 'City General Hospital',
      opdName: 'Cardiology OPD',
      doctorName: 'Dr. Perera',
      date: '2026-10-15',
      timeSlot: '09:00 AM',
      status: 'upcoming',
    },
    {
      patientId: patient._id,
      hospitalName: 'National Hospital',
      opdName: 'Neurology OPD',
      doctorName: 'Dr. Silva',
      date: '2026-10-20',
      timeSlot: '11:00 AM',
      status: 'upcoming',
    },
  ]);

  console.log('2 appointments seeded successfully!');
  process.exit(0);
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
