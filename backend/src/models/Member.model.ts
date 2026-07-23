import mongoose, { Schema, Document } from 'mongoose';

export interface IMember extends Document {
  gymId: mongoose.Types.ObjectId;
  name: string;
  email: string;
  phone: string;
  membershipPlan: string;
  status: string; // 'Active', 'Expired', 'Expiring Soon'
  joinDate: Date;
  expiryDate: Date;
  totalCheckIns: number;
  imageUrl?: string;
  dob?: Date;
  address?: string;
  documentUrl?: string;
  trainerId?: mongoose.Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
}

const MemberSchema: Schema = new Schema(
  {
    gymId: { type: mongoose.Schema.Types.ObjectId, ref: 'Gym', required: true },
    name: { type: String, required: true },
    email: { type: String, required: true },
    phone: { type: String, default: '' },
    membershipPlan: { type: String, required: true },
    status: { type: String, default: 'Active' },
    joinDate: { type: Date, default: Date.now },
    expiryDate: { type: Date, required: true },
    totalCheckIns: { type: Number, default: 0 },
    imageUrl: { type: String, default: '' },
    dob: { type: Date },
    address: { type: String, default: '' },
    documentUrl: { type: String, default: '' },
    trainerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Trainer' },
  },
  { timestamps: true }
);

export default mongoose.model<IMember>('Member', MemberSchema);
