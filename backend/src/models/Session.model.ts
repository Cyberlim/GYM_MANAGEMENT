import mongoose, { Schema, Document } from 'mongoose';

export interface ISession extends Document {
  userId: mongoose.Types.ObjectId;
  token: string;
  userAgent: string;
  ipAddress: string;
  lastActive: Date;
  createdAt: Date;
}

const SessionSchema: Schema = new Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  token: { type: String, required: true },
  userAgent: { type: String, default: 'Unknown Device' },
  ipAddress: { type: String, default: 'Unknown IP' },
  lastActive: { type: Date, default: Date.now },
  createdAt: { type: Date, default: Date.now, expires: '30d' } // Auto-delete after 30 days
});

export default mongoose.model<ISession>('Session', SessionSchema);
