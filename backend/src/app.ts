import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Basic health check route
app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'success', message: 'API is running' });
});

// Import and mount routes here later
import authRoutes from './routes/auth.routes';
import gymRoutes from './routes/gym.routes';
import memberRoutes from './routes/member.routes';
import trainerRoutes from './routes/trainer.routes';
import staffRoutes from './routes/staff.routes';
import planRoutes from './routes/plan.routes';
import paymentRoutes from './routes/payment.routes';
import expenseRoutes from './routes/expense.routes';
import equipmentRoutes from './routes/equipment.routes';
import inventoryRoutes from './routes/inventory.routes';
import dashboardRoutes from './routes/dashboard.routes';
import superadminRoutes from './routes/superadmin.routes';
import uploadRoutes from './routes/upload.routes';
import supportRoutes from './routes/support.routes';
import notificationRoutes from './routes/notification.routes';
import eventRoutes from './routes/event.routes';
import memberAuthRoutes from './routes/member.auth.routes';
import attendanceRoutes from './routes/attendance.routes';

app.use('/api/auth', authRoutes);
app.use('/api/gyms', gymRoutes);
app.use('/api/members', memberRoutes);
app.use('/api/trainers', trainerRoutes);
app.use('/api/staff', staffRoutes);
app.use('/api/plans', planRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/expenses', expenseRoutes);
app.use('/api/equipment', equipmentRoutes);
app.use('/api/inventory', inventoryRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/superadmin', superadminRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/support', supportRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/events', eventRoutes);
app.use('/api/member-app', memberAuthRoutes);
app.use('/api/attendance', attendanceRoutes);

// Global Error Handler
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Global Error:', err);
  res.status(err.status || 500).json({
    message: err.message || 'Internal Server Error',
    error: process.env.NODE_ENV === 'development' ? err : {}
  });
});

export default app;
