import mongoose, { Schema, Document } from 'mongoose';

export interface IEvent extends Document {
  userId: string;
  title: string;
  description?: string;
  date: Date;
  color?: string;
  createdAt: Date;
  updatedAt: Date;
}

const EventSchema: Schema = new Schema(
  {
    userId: { type: String, required: true, index: true },
    title: { type: String, required: true },
    description: { type: String },
    date: { type: Date, required: true },
    color: { type: String, default: '#2196F3' }, // Default blue color
  },
  { timestamps: true }
);

export default mongoose.model<IEvent>('Event', EventSchema);
