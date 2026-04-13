import { Controller, Get, Post, Body, Query, UseInterceptors, UploadedFile, BadRequestException } from '@nestjs/common';
import { StoryService } from './stories.service';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';

@Controller('stories')
export class StoryController {
  constructor(private readonly storyService: StoryService) {}

  @Get('get_stories')
  async getStories(@Query('user_id') userId: string) {
    if (!userId) throw new BadRequestException('User ID is required');
    const result = await this.storyService.getStories(parseInt(userId));
    return { success: true, data: result };
  }

  @Post('add_story')
  @UseInterceptors(FileInterceptor('media'))
  async addStory(@Body() body: any, @UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('Media file is required');
    const { user_id, media_type } = body;
    const result = await this.storyService.addStoryWithCloudinary(
      parseInt(user_id),
      file,
      media_type || (file.mimetype.startsWith('video') ? 'video' : 'image'),
    );
    return { success: true, data: result };
  }


  @Post('toggle_story_like')
  async toggleLike(@Body() body: any) {
    const { user_id, story_id } = body;
    const result = await this.storyService.toggleLike(parseInt(user_id), parseInt(story_id));
    return { success: true, ...result };
  }

  @Post('mark_story_viewed')
  async markViewed(@Body() body: any) {
    const { user_id, story_id } = body;
    await this.storyService.markViewed(parseInt(user_id), parseInt(story_id));
    return { success: true };
  }
}
