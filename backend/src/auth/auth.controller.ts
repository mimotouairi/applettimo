import { Controller, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';

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
  async updateProfile(@Body() body: any) {
    const result = await this.authService.updateProfile(body);
    return { success: true, data: result };
  }

  @Post('update_profile_v2')
  async updateProfileV2(@Body() body: any) {
    const result = await this.authService.updateProfileV2(body);
    return { success: true, data: result };
  }

  @Post('switch_account')
  async switchAccount(@Body() body: any) {
    const result = await this.authService.switchAccount(body.user_id);
    return { success: true, data: result };
  }
}
