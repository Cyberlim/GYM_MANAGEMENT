import { Response } from 'express';
import Gym from '../models/Gym.model';
import Plan from '../models/Plan.model';
import { AuthRequest } from '../middlewares/auth.middleware';

export const setupGym = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { name, address, contactPhone } = req.body;
    let logo = '';

    if (req.file) {
      logo = `http://localhost:5000/uploads/${req.file.filename}`;
    }

    if (!name || !address || !contactPhone) {
      res.status(400).json({ message: 'Please provide name, address, and contact phone' });
      return;
    }

    // Check if user already has a gym setup
    const existingGym = await Gym.findOne({ ownerId: req.user._id });
    
    if (existingGym) {
      // Update existing gym
      existingGym.name = name;
      existingGym.address = address;
      existingGym.contactPhone = contactPhone;
      if (logo) {
        existingGym.logo = logo;
      }
      const updatedGym = await existingGym.save();
      res.status(200).json(updatedGym);
      return;
    }

    // Create new gym
    const gym = await Gym.create({
      ownerId: req.user._id,
      name,
      address,
      contactPhone,
      logo,
    });

    // Seed default inactive plans for the new gym owner
    const defaultPlans = [
      {
        gymId: gym._id,
        name: 'Basic Plan',
        price: 1500,
        duration: '1 Month',
        features: ['Gym Access', 'Locker Facility'],
        colorHex: '#3b82f6',
        currencySymbol: '₹',
        isActive: false
      },
      {
        gymId: gym._id,
        name: 'Pro Plan',
        price: 4000,
        discountPrice: 3500,
        duration: '3 Months',
        features: ['Gym Access', 'Locker Facility', 'Diet Plan'],
        colorHex: '#8b5cf6',
        currencySymbol: '₹',
        isActive: false
      },
      {
        gymId: gym._id,
        name: 'Elite Plan',
        price: 12000,
        discountPrice: 10000,
        duration: '12 Months',
        features: ['Gym Access', 'Locker Facility', 'Diet Plan', 'Personal Trainer (2 sessions/mo)'],
        colorHex: '#f59e0b',
        currencySymbol: '₹',
        isActive: false
      }
    ];

    await Plan.insertMany(defaultPlans);

    // --- Dispatch Notification for New Gym Signup ---
    try {
      const User = require('../models/User.model').default;
      const Notification = require('../models/Notification.model').default;
      const io = require('../services/socket').getIO();
      const superadmins = await User.find({ role: 'superadmin' });
      for (const admin of superadmins) {
        if (admin.settings && admin.settings.newGymSignups === true) {
          const notif = await Notification.create({
            userId: admin._id,
            title: 'New Gym Registered',
            message: `${gym.name} has registered on the platform.`,
            type: 'registration',
            route: `/gyms/${gym._id}`,
          });
          io.to('superadmin').emit('notification', notif);
        }
      }
    } catch (notifErr) {
      console.error('Error dispatching signup notification:', notifErr);
    }

    res.status(201).json(gym);
  } catch (error: any) {
    console.error('Setup Gym Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const subscribePlan = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { plan, isTrialActive } = req.body;

    if (!plan) {
      res.status(400).json({ message: 'Please provide a plan' });
      return;
    }

    const gym = await Gym.findOne({ ownerId: req.user._id });
    if (!gym) {
      res.status(404).json({ message: 'Gym not found. Please complete gym setup first.' });
      return;
    }

    gym.subscriptionPlan = plan;
    gym.trialActive = isTrialActive;

    const updatedGym = await gym.save();
    res.status(200).json(updatedGym);
  } catch (error: any) {
    console.error('Subscribe Plan Error:', error);
    res.status(500).json({ message: error.message });
  }
};
