import { Injectable } from '@nestjs/common';
import { v2 as cloudinary } from 'cloudinary';
import { CloudinaryResponse } from './cloudinary-response';
const streamifier = require('streamifier');

@Injectable()
export class CloudinaryService {
  async uploadFile(file: Express.Multer.File): Promise<CloudinaryResponse> {
    console.log(`[Cloudinary] Starting upload: ${file.originalname} (${file.mimetype})`);
    try {
      return await new Promise((resolve, reject) => {
        const upload = cloudinary.uploader.upload_stream((error, result) => {
          if (error) {
            console.error('[Cloudinary] Upload Error:', error);
            return reject(error);
          }
          if (result) {
            console.log('[Cloudinary] Upload success:', result.secure_url);
            resolve(result);
          } else {
            console.error('[Cloudinary] Upload failed: No result');
            reject(new Error('Cloudinary upload returned undefined result'));
          }
        });

        streamifier.createReadStream(file.buffer).pipe(upload);
      });
    } catch (err) {
      console.error('[Cloudinary] Critical Service Error:', err);
      throw err;
    }
  }
}
