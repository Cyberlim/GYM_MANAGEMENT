import mongoose, { Schema, Document } from 'mongoose';

export interface ITrainer extends Document {
  gymId: mongoose.Types.ObjectId;
  name: string;
  specialization: string;
  assignedMembers: number;
  rating: number;
  imageUrl?: string;
  email: string;
  phone: string;
  experienceYears: number;
  about: string;
  certificates: string[];
  createdAt: Date;
  updatedAt: Date;
}

const TrainerSchema: Schema = new Schema(
  {
    gymId: { type: mongoose.Schema.Types.ObjectId, ref: 'Gym', required: true },
    name: { type: String, required: true },
    specialization: { type: String, required: true },
    assignedMembers: { type: Number, default: 0 },
    rating: { type: Number, default: 0.0 },
    imageUrl: { type: String, default: '' },
    email: { type: String, default: '' },
    phone: { type: String, default: '' },
    experienceYears: { type: Number, default: 0 },
    about: { type: String, default: '' },
    certificates: { type: [String], default: [] },
  },
  { timestamps: true }
);

export default mongoose.model<ITrainer>('Trainer', TrainerSchema);
