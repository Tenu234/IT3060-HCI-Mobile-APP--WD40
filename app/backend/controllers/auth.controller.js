const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const generateToken = (user) =>
  jwt.sign(
    { id: user._id, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );

// POST /api/auth/register
// Public route — role is ALWAYS hardcoded to 'patient'
exports.register = async (req, res) => {
  try {
    const { name, email, password, phone, nic } = req.body;

    // Validate required fields
    if (!name || !email || !password || !phone || !nic) {
      return res.status(400).json({ message: 'All fields are required.' });
    }

    // Check for existing account
    const existingUser = await User.findOne({ $or: [{ email }, { nic }] });
    if (existingUser) {
      const field = existingUser.email === email ? 'Email' : 'NIC';
      return res.status(409).json({ message: `${field} is already registered.` });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 12);

    // Save user — role hardcoded to 'patient', never from req.body
    const user = await User.create({
      name,
      email,
      password: hashedPassword,
      phone,
      nic,
      role: 'patient',
    });

    const token = generateToken(user);

    return res.status(201).json({
      token,
      id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
    });
  } catch (err) {
    console.error('Register error:', err);
    return res.status(500).json({ message: 'Server error. Please try again.' });
  }
};

// POST /api/auth/login
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required.' });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ message: 'Invalid email or password.' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid email or password.' });
    }

    const token = generateToken(user);

    console.log('Login response role:', user.role); // debug

    return res.status(200).json({
      token,
      id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
    });
  } catch (err) {
    console.error('Login error:', err);
    return res.status(500).json({ message: 'Server error. Please try again.' });
  }
};
