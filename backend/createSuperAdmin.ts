import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';
import User from './src/models/User.model';

// Initialize env
dotenv.config();

async function run() {
  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGO_URI as string);
    console.log('Connected.');

    const email = 'admin.gymcrm@gmail.com';
    const password = 'AdminGYMCRM1234';
    
    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Check if user already exists
    const existing = await User.findOne({ email });
    if (existing) {
      console.log('User already exists, updating password and role...');
      existing.password = hashedPassword;
      existing.role = 'superadmin';
      existing.isEmailVerified = true;
      await existing.save();
      console.log('Superadmin updated successfully.');
    } else {
      console.log('Creating new superadmin...');
      const user = new User({
        name: 'Super Admin',
        email: email,
        password: hashedPassword,
        role: 'superadmin',
        isEmailVerified: true,
        authProvider: 'local',
        twoFactorMethod: 'none',
      });
      await user.save();
      console.log('Superadmin created successfully.');
    }
    process.exit(0);
  } catch (error) {
    console.error('Error creating superadmin:', error);
    process.exit(1);
  }
}

run();
