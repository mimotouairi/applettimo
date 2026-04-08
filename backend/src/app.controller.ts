import { Controller, Post, UseInterceptors, UploadedFile } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';

@Controller()
export class AppController {
  @Post('upload_media')
  @UseInterceptors(FileInterceptor('media', {
    storage: diskStorage({
      destination: './uploads',
      filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        cb(null, uniqueSuffix + extname(file.originalname));
      }
    }),
    fileFilter: (req, file, cb) => {
      // Accept images and videos
      if (!file.originalname.match(/\.(jpg|jpeg|png|gif|mp4|mov|avi|mkv|webm)$/i)) {
        return cb(new Error('Only image and video files are allowed!'), false);
      }
      cb(null, true);
    }
  }))
  uploadMedia(@UploadedFile() file: Express.Multer.File) {
    if (!file) {
      return { success: false, message: 'No file uploaded' };
    }
    
    // Return relative path. The frontend's api_service handles adding the base url
    return { 
      success: true, 
      data: { url: `uploads/${file.filename}` } 
    };
  }
}
