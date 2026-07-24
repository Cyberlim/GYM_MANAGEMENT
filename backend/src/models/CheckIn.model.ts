import mongoose, { Schema, Document } from 'mongoose';

export interface ICheckIn extends Document {
  gymId: mongoose.Types.ObjectId;
  personId: mongoose.Types.ObjectId;
  role: string; // 'Member', 'Staff', 'Trainer'
  date: Date;
  checkInTime?: Date;
  status: string; // 'Present', 'Late', 'Absent'
  createdAt: Date;
  updatedAt: Date;
}

const CheckInSchema: Schema = new Schema(
  {
    gymId: { type: mongoose.Schema.Types.ObjectId, ref: 'Gym', required: true },
    personId: { type: mongoose.Schema.Types.ObjectId, required: true },
    role: { type: String, required: true, enum: ['Member', 'Staff', 'Trainer'] },
    date: { type: Date, required: true },
    checkInTime: { type: Date },
    status: { type: String, default: 'Present', enum: ['Present', 'Late', 'Absent'] },
  },
  { timestamps: true }
);

export default mongoose.model<ICheckIn>('CheckIn', CheckInSchema);
