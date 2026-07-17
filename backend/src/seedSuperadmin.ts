import mongoose from 'mongoose';
import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';
import User from './models/User.model';

dotenv.config();

const seedSuperadmin = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/gym_management');
    console.log('MongoDB Connected');

    const email = 'admin.gymcrm@gmail.com';
    let user = await User.findOne({ email });

    if (user) {
      console.log('Superadmin already exists. Updating password to AdminGYMCRM1234');
      const salt = await bcrypt.genSalt(10);
      user.password = await bcrypt.hash('AdminGYMCRM1234', salt);
      user.role = 'superadmin';
      user.isEmailVerified = true;
      user.set('settings.twoFactorEnabled', false);
      user.twoFactorMethod = 'none';
      await user.save();
    } else {
      console.log('Creating Superadmin...');
      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash('AdminGYMCRM1234', salt);

      await User.create({
        name: 'Super Admin',
        email,
        password: hashedPassword,
        authProvider: 'local',
        role: 'superadmin',
        isEmailVerified: true,
      });
    }

    console.log('Superadmin seeded successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Error seeding superadmin:', error);
    process.exit(1);
  }
};

seedSuperadmin();
