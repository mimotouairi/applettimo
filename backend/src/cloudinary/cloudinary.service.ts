import { Injectable } from '@nestjs/common';
import { v2 as cloudinary } from 'cloudinary';
import { CloudinaryResponse } from './cloudinary-response';
const streamifier = require('streamifier');

@Injectable()
export class CloudinaryService {
  async uploadFile(file: Express.Multer.File): Promise<CloudinaryResponse> {
    console.log(`[Cloudinary] Starting upload: ${file.originalname} (${file.mimetype}) - Size: ${file.size} bytes`);
    
    try {
      // For large files (>20MB) or videos, use upload_large for better stability (chunked upload)
      if (file.size > 20 * 1024 * 1024 || file.mimetype.startsWith('video')) {
        console.log('[Cloudinary] Using upload_large (chunked) for stability');
        return await new Promise((resolve, reject) => {
          cloudinary.uploader.upload_large(
            file.path, // Use file path for disk storage
            {
              resource_type: 'auto',
              chunk_size: 6000000, // 6MB chunks
            },
            (error, result) => {
              if (error) {
                console.error('[Cloudinary] Upload Error:', error);
                return reject(error);
              }
              resolve(result as CloudinaryResponse);
            }
          );
        });
      }

      // For smaller files, we can still use stream or direct upload
      return await new Promise((resolve, reject) => {
        const upload = cloudinary.uploader.upload_stream(
          { resource_type: 'auto' },
          (error, result) => {
            if (error) {
              console.error('[Cloudinary] Upload Error:', error);
              return reject(error);
            }
            resolve(result as CloudinaryResponse);
          }
        );

        if (file.buffer) {
          streamifier.createReadStream(file.buffer).pipe(upload);
        } else if (file.path) {
          const fs = require('fs');
          fs.createReadStream(file.path).pipe(upload);
        } else {
          reject(new Error('File buffer or path is missing'));
        }
      });
    } catch (err) {
      console.error('[Cloudinary] Critical Service Error:', err);
      throw err;
    }
  }
}
