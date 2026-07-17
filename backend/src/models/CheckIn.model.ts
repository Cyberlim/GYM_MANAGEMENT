import mongoose, { Schema, Document } from 'mongoose';

export interface ICheckIn extends Document {
  gymId: mongoose.Types.ObjectId;
  personId: mongoose.Types.ObjectId;
  role: string; // 'Member', 'Staff', 'Trainer'
  checkInTime: Date;
  status: string; // 'Present', 'Late'
  createdAt: Date;
  updatedAt: Date;
}

const CheckInSchema: Schema = new Schema(
  {
    gymId: { type: mongoose.Schema.Types.ObjectId, ref: 'Gym', required: true },
    personId: { type: mongoose.Schema.Types.ObjectId, required: true },
    role: { type: String, required: true, enum: ['Member', 'Staff', 'Trainer'] },
    checkInTime: { type: Date, default: Date.now },
    status: { type: String, default: 'Present' },
  },
  { timestamps: true }
);

export default mongoose.model<ICheckIn>('CheckIn', CheckInSchema);
