import { Controller, Get, Post, Body, Query } from '@nestjs/common';
import { UserService } from './user.service';

@Controller('users')
export class UserController {
  constructor(private userService: UserService) {}

  @Get('get_user_profile')
  async getUserProfile(@Query('profile_id') profile_id: string, @Query('current_user_id') current_user_id: string) {
    const result = await this.userService.getUserProfile(profile_id, current_user_id);
    return { success: true, data: result };
  }

  @Post('toggle_follow')
  async toggleFollow(@Body() body: any) {
    const { user_id, profile_id } = body;
    const result = await this.userService.toggleFollow(user_id, profile_id);
    return { success: true, ...result };
  }

  @Get('search_users')
  async searchUsers(@Query('q') q: string, @Query('current_user_id') current_user_id: string) {
    const result = await this.userService.searchUsers(q, current_user_id);
    return { success: true, data: result };
  }

  @Get('get_suggested_users')
  async getSuggestedUsers(@Query('current_user_id') current_user_id: string) {
    const result = await this.userService.getSuggestedUsers(current_user_id);
    return { success: true, data: result };
  }

  @Get('get_user_stats')
  async getUserStats(@Query('user_id') user_id: string) {
    const result = await this.userService.getUserStats(user_id);
    return { success: true, data: result };
  }

  @Get('get_notifications')
  async getNotifications(@Query('user_id') user_id: string) {
    const result = await this.userService.getNotifications(user_id);
    return { success: true, data: result };
  }

  @Post('mark_notification_read')
  async markNotificationRead(@Body() body: any) {
    const { user_id, notification_id } = body;
    const result = await this.userService.markNotificationRead(
      user_id,
      notification_id,
    );
    return result;
  }

  @Post('mark_all_notifications_read')
  async markAllNotificationsRead(@Body() body: any) {
    const { user_id } = body;
    const result = await this.userService.markAllNotificationsRead(user_id);
    return result;
  }
}
