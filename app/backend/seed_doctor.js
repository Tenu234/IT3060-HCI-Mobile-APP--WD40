const dns = require('node:dns');
dns.setServers(['1.1.1.1', '8.8.8.8']);

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./models/User');
const Appointment = require('./models/Appointment');
const DispatchAlert = require('./models/DispatchAlert');
require('dotenv').config();

async function seedDoctor() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('MongoDB connected for doctor seed');

  // 1. Create or update Doctor user
  const doctorEmail = 'doctor@opd.lk';
  let doctor = await User.findOne({ email: doctorEmail });
  const hashedPassword = await bcrypt.hash('password123', 12);

  if (!doctor) {
    doctor = await User.create({
      name: 'Dr. RKAM Deshan',
      email: doctorEmail,
      password: hashedPassword,
      phone: '0771234567',
      nic: '199201234567',
      role: 'doctor',
    });
    console.log('Created doctor user:', doctor.name);
  } else {
    doctor.role = 'doctor';
    doctor.name = 'Dr. RKAM Deshan';
    doctor.password = hashedPassword;
    await doctor.save();
    console.log('Updated doctor user:', doctor.name);
  }

  // 2. Ensure patient users exist
  const samplePatients = [
    { name: 'Kavindu Perera', email: 'kavindu@test.lk', phone: '0711111111', nic: '200111111111' },
    { name: 'Anula Wijesinghe', email: 'anula@test.lk', phone: '0722222222', nic: '196522222222' },
    { name: 'Sunil Shantha', email: 'sunil@test.lk', phone: '0733333333', nic: '198533333333' },
    { name: 'Chamari Silva', email: 'chamari@test.lk', phone: '0744444444', nic: '199844444444' },
    { name: 'Nimal Jayawardena', email: 'nimal@test.lk', phone: '0755555555', nic: '197455555555' },
  ];

  const patientDocs = [];
  for (const p of samplePatients) {
    let pt = await User.findOne({ email: p.email });
    if (!pt) {
      pt = await User.create({
        ...p,
        password: hashedPassword,
        role: 'patient',
      });
    }
    patientDocs.push(pt);
  }

  // 3. Clean and recreate today's queue
  await Appointment.deleteMany({ doctorName: 'Dr. RKAM Deshan' });

  const todayStr = new Date().toISOString().split('T')[0];

  const queueItems = [
    {
      patientId: patientDocs[0]._id,
      patientName: patientDocs[0].name,
      tokenNumber: 'A-101',
      hospitalName: 'National Hospital Colombo',
      opdName: 'General OPD',
      doctorName: 'Dr. RKAM Deshan',
      roomNumber: 'Consultation Room 2',
      date: todayStr,
      timeSlot: '08:30 AM',
      symptoms: 'Mild fever and sore throat for 3 days',
      status: 'completed',
      clinicalNotes: 'Throat erythematous, no exudates. Chest clear.',
      diagnosis: 'Acute Viral Pharyngitis',
      prescription: 'Paracetamol 500mg TDS x 3d, Warm saline gargle',
      consultationStartTime: new Date(Date.now() - 3600000),
      consultationEndTime: new Date(Date.now() - 3000000),
    },
    {
      patientId: patientDocs[1]._id,
      patientName: patientDocs[1].name,
      tokenNumber: 'A-102',
      hospitalName: 'National Hospital Colombo',
      opdName: 'General OPD',
      doctorName: 'Dr. RKAM Deshan',
      roomNumber: 'Consultation Room 2',
      date: todayStr,
      timeSlot: '09:00 AM',
      symptoms: 'Follow-up for chronic hypertension and dizziness',
      status: 'in_consultation',
      clinicalNotes: 'BP 140/90 mmHg. Heart sounds normal.',
      diagnosis: 'Essential Hypertension - Under review',
      prescription: 'Losartan 50mg daily. Review BP chart in 2 weeks.',
      consultationStartTime: new Date(Date.now() - 600000),
    },
    {
      patientId: patientDocs[2]._id,
      patientName: patientDocs[2].name,
      tokenNumber: 'A-103',
      hospitalName: 'National Hospital Colombo',
      opdName: 'General OPD',
      doctorName: 'Dr. RKAM Deshan',
      roomNumber: 'Consultation Room 2',
      date: todayStr,
      timeSlot: '09:15 AM',
      symptoms: 'Acute lumbar back pain after heavy lifting',
      status: 'waiting',
      clinicalNotes: '',
      diagnosis: '',
      prescription: '',
    },
    {
      patientId: patientDocs[3]._id,
      patientName: patientDocs[3].name,
      tokenNumber: 'A-104',
      hospitalName: 'National Hospital Colombo',
      opdName: 'General OPD',
      doctorName: 'Dr. RKAM Deshan',
      roomNumber: 'Consultation Room 2',
      date: todayStr,
      timeSlot: '09:30 AM',
      symptoms: 'Persistent dry cough and fatigue for 1 week',
      status: 'waiting',
      clinicalNotes: '',
      diagnosis: '',
      prescription: '',
    },
    {
      patientId: patientDocs[4]._id,
      patientName: patientDocs[4].name,
      tokenNumber: 'A-105',
      hospitalName: 'National Hospital Colombo',
      opdName: 'General OPD',
      doctorName: 'Dr. RKAM Deshan',
      roomNumber: 'Consultation Room 2',
      date: todayStr,
      timeSlot: '09:45 AM',
      symptoms: 'Abdominal cramps after meal',
      status: 'waiting',
      clinicalNotes: '',
      diagnosis: '',
      prescription: '',
    },
  ];

  await Appointment.insertMany(queueItems);
  console.log('Seeded 5 appointments in queue');

  // 4. Seed initial dispatch alerts
  await DispatchAlert.deleteMany({});
  await DispatchAlert.insertMany([
    {
      doctorId: doctor._id,
      doctorName: doctor.name,
      tokenNumber: 'A-101',
      patientName: patientDocs[0].name,
      roomNumber: 'Consultation Room 2',
      message: 'Token A-101 enter Consultation Room 2',
      alertType: 'queue_call',
      priority: 'normal',
      status: 'dismissed',
      createdAt: new Date(Date.now() - 3600000),
    },
    {
      doctorId: doctor._id,
      doctorName: doctor.name,
      tokenNumber: 'A-102',
      patientName: patientDocs[1].name,
      roomNumber: 'Consultation Room 2',
      message: 'Token A-102 enter Consultation Room 2',
      alertType: 'queue_call',
      priority: 'urgent',
      status: 'active',
      createdAt: new Date(Date.now() - 600000),
    },
  ]);
  console.log('Seeded dispatch alerts');

  console.log('\n--- DOCTOR LOGIN CREDENTIALS ---');
  console.log('Email: doctor@opd.lk');
  console.log('Password: password123');
  console.log('Role: doctor');
  console.log('--------------------------------\n');

  process.exit(0);
}

seedDoctor().catch((err) => {
  console.error('Seed doctor failed:', err);
  process.exit(1);
});
