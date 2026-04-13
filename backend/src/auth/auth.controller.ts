import { Controller, Post, Body, UseInterceptors, UploadedFile, UploadedFiles } from '@nestjs/common';
import { AuthService } from './auth.service';
import { FileInterceptor, FileFieldsInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('register')
  async register(@Body() body: any) {
    const result = await this.authService.register(body);
    return { success: true, data: result };
  }

  @Post('login')
  async login(@Body() body: any) {
    const { login_id, password } = body;
    const result = await this.authService.login(login_id, password);
    return { success: true, data: result };
  }

  @Post('update_profile')
  @UseInterceptors(FileInterceptor('photo'))
  async updateProfile(@Body() body: any, @UploadedFile() file: Express.Multer.File) {
    const result = await this.authService.updateProfileWithCloudinary(body, file);
    return { success: true, data: result };
  }

  @Post('update_profile_v2')
  @UseInterceptors(FileFieldsInterceptor([
    { name: 'photo', maxCount: 1 },
    { name: 'coverPhoto', maxCount: 1 }
  ]))
  async updateProfileV2(@Body() body: any, @UploadedFiles() files: { photo?: Express.Multer.File[], coverPhoto?: Express.Multer.File[] }) {
    const result = await this.authService.updateProfileV2WithCloudinary(body, files);
    return { success: true, data: result };
  }


  @Post('switch_account')
  async switchAccount(@Body() body: any) {
    const result = await this.authService.switchAccount(body.user_id);
    return { success: true, data: result };
  }
}
