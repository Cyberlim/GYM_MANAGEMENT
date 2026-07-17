import mongoose, { Schema, Document } from 'mongoose';

export interface IEquipment extends Document {
  gymId: mongoose.Types.ObjectId;
  machineName: string;
  equipmentType: string;
  brand: string;
  purchaseDate: Date;
  purchasePrice: number;
  status: string;
  location: string;
  warrantyExpiry?: Date;
  supplier?: string;
  serialNumber?: string;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

const EquipmentSchema: Schema = new Schema(
  {
    gymId: { type: mongoose.Schema.Types.ObjectId, ref: 'Gym', required: true },
    machineName: { type: String, required: true },
    equipmentType: { 
      type: String, 
      required: true,
      enum: ['Cardio', 'Strength', 'Free Weights', 'Functional Training', 'Accessories', 'Recovery Equipment']
    },
    brand: { type: String, required: true },
    purchaseDate: { type: Date, required: true },
    purchasePrice: { type: Number, required: true },
    status: { 
      type: String, 
      required: true,
      enum: ['Active', 'Under Maintenance', 'Under Repair', 'Damaged', 'Retired']
    },
    location: { type: String, required: true },
    warrantyExpiry: { type: Date },
    supplier: { type: String },
    serialNumber: { type: String },
    notes: { type: String },
  },
  { timestamps: true }
);

export default mongoose.model<IEquipment>('Equipment', EquipmentSchema);
