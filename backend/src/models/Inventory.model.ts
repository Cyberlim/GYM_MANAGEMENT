import mongoose, { Schema, Document } from 'mongoose';

export interface IInventory extends Document {
  gymId: mongoose.Types.ObjectId;
  itemName: string;
  category: string;
  quantity: number;
  unit: string;
  purchasePrice: number;
  sellingPrice?: number;
  supplier?: string;
  purchaseDate?: Date;
  expiryDate?: Date;
  minimumStock?: number;
  createdAt: Date;
  updatedAt: Date;
}

const InventorySchema: Schema = new Schema(
  {
    gymId: { type: mongoose.Schema.Types.ObjectId, ref: 'Gym', required: true },
    itemName: { type: String, required: true },
    category: { 
      type: String, 
      required: true,
      enum: ['Supplements', 'Beverages', 'Merchandise', 'Cleaning Supplies', 'Office Supplies', 'Accessories', 'Nutrition', 'Snacks', 'Miscellaneous']
    },
    quantity: { type: Number, required: true, default: 0 },
    unit: { 
      type: String, 
      required: true,
      enum: ['Box', 'Bottle', 'Piece']
    },
    purchasePrice: { type: Number, required: true, default: 0 },
    sellingPrice: { type: Number },
    supplier: { type: String },
    purchaseDate: { type: Date },
    expiryDate: { type: Date },
    minimumStock: { type: Number, default: 0 },
  },
  { timestamps: true }
);

export default mongoose.model<IInventory>('Inventory', InventorySchema);
