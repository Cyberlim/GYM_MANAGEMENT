import { Request, Response } from 'express';
import Event from '../models/Event.model';

interface AuthRequest extends Request {
  user?: any;
}

export const getEvents = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user._id.toString();

    const events = await Event.find({ userId }).sort({ date: 1 });
    res.status(200).json(events);
  } catch (error: any) {
    console.error('Get Events Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const createEvent = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user._id.toString();

    const { title, date, description, color } = req.body;
    if (!title || !date) {
      res.status(400).json({ message: 'Please provide title and date' });
      return;
    }

    const newEvent = new Event({
      userId,
      title,
      description,
      date: new Date(date),
      color,
    });

    const savedEvent = await newEvent.save();
    res.status(201).json(savedEvent);
  } catch (error: any) {
    console.error('Create Event Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const deleteEvent = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user._id.toString();
    const eventId = req.params.eventId as string;

    const deletedEvent = await Event.findOneAndDelete({ _id: eventId, userId });
    
    if (!deletedEvent) {
      res.status(404).json({ message: 'Event not found or unauthorized' });
      return;
    }

    res.status(200).json({ message: 'Event deleted successfully' });
  } catch (error: any) {
    console.error('Delete Event Error:', error);
    res.status(500).json({ message: error.message });
  }
};
