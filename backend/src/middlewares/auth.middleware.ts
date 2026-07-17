import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import User from '../models/User.model';

export interface AuthRequest extends Request {
  user?: any;
}

export const protect = async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  let token;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      // Get token from header
      token = req.headers.authorization.split(' ')[1];

      if (!token) throw new Error('Token is undefined');

      // Verify token
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'super_secret_fallback') as any;

      // Get user from the token
      req.user = await User.findById(decoded.id).select('-password');

      if (req.user && req.user.status === 'suspended') {
        res.status(403).json({ message: 'Account Suspended', isSuspended: true, suspensionId: req.user.suspensionId });
        return;
      }

      next();
    } catch (error) {
      console.error(error);
      res.status(401).json({ message: 'Not authorized, token failed' });
    }
  }

  if (!token) {
    res.status(401).json({ message: 'Not authorized, no token' });
  }
};
