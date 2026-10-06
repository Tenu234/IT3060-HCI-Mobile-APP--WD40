const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name:  { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true },
    password: { type: String, required: true },
    phone: { type: String, required: true },
    nic:   { type: String, required: true, unique: true },
    // Role is never accepted from request body on public routes
    role:  { type: String, enum: ['patient', 'doctor', 'nurse', 'admin'], default: 'patient' },
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', userSchema);
