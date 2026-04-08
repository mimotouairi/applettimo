import { Controller, Get, Post, Body, Query, UseInterceptors, UploadedFile } from '@nestjs/common';
import { PostService } from './post.service';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';

@Controller('posts')
export class PostController {
  constructor(private postService: PostService) {}

  @Get('get_posts')
  async getPosts(@Query('user_id') user_id: string, @Query('limit') limit: string, @Query('offset') offset: string) {
    const result = await this.postService.getPosts(user_id, limit, offset);
    return { success: true, data: result };
  }

  @Get('get_videos')
  async getVideos(@Query('user_id') user_id: string) {
    const result = await this.postService.getVideos(user_id);
    return { success: true, data: result };
  }

  @Get('get_saved_posts')
  async getSavedPosts(@Query('user_id') user_id: string) {
    const result = await this.postService.getSavedPosts(user_id);
    return { success: true, data: result };
  }

  @Post('create_post')
  @UseInterceptors(FileInterceptor('media', {
    storage: diskStorage({
      destination: './uploads',
      filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        cb(null, uniqueSuffix + extname(file.originalname));
      }
    })
  }))
  async createPost(@Body() body: any, @UploadedFile() file: Express.Multer.File) {
    const result = await this.postService.createPost(body, file);
    return { success: true, data: result };
  }

  @Post('repost_post')
  async repostPost(@Body() body: any) {
    const { user_id, post_id } = body;
    const result = await this.postService.repostPost(user_id, post_id);
    return result;
  }

  @Post('toggle_like')
  async toggleLike(@Body() body: any) {
    const { user_id, post_id } = body;
    const result = await this.postService.toggleLike(user_id, post_id);
    return { success: true, ...result };
  }

  @Post('toggle_save')
  async toggleSave(@Body() body: any) {
    const { user_id, post_id } = body;
    const result = await this.postService.toggleSave(user_id, post_id);
    return { success: true, ...result };
  }

  @Post('delete_post')
  async deletePost(@Body() body: any) {
    const { user_id, post_id } = body;
    const result = await this.postService.deletePost(user_id, post_id);
    return { success: true, ...result };
  }
}
