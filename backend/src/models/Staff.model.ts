import mongoose, { Schema, Document } from 'mongoose';

export interface IStaff extends Document {
  gymId: mongoose.Types.ObjectId;
  name: string;
  role: string;
  shift: string;
  phone: string;
  email: string;
  dob?: Date;
  imageUrl?: string;
  idProofUrl?: string;
  createdAt: Date;
  updatedAt: Date;
}

const StaffSchema: Schema = new Schema(
  {
    gymId: { type: mongoose.Schema.Types.ObjectId, ref: 'Gym', required: true },
    name: { type: String, required: true },
    role: { type: String, required: true },
    shift: { type: String, required: true },
    phone: { type: String, default: '' },
    email: { type: String, default: '' },
    dob: { type: Date },
    imageUrl: { type: String, default: '' },
    idProofUrl: { type: String, default: '' },
  },
  { timestamps: true }
);

export default mongoose.model<IStaff>('Staff', StaffSchema);
