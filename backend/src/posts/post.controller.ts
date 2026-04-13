import { Controller, Get, Post, Body, Query, UseInterceptors, UploadedFile, UploadedFiles } from '@nestjs/common';
import { PostService } from './post.service';
import { FileInterceptor, FilesInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';

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

  @Get('get_post')
  async getPost(@Query('user_id') user_id: string, @Query('post_id') post_id: string) {
    const result = await this.postService.getPostById(user_id, post_id);
    return { success: true, data: result };
  }

  @Post('create_post')
  @UseInterceptors(FileInterceptor('media', {
    storage: memoryStorage()
  }))
  async createPost(@Body() body: any, @UploadedFile() file: Express.Multer.File) {
    console.log('--- [PostController] New create_post request ---');
    console.log('User ID:', body.user_id);
    console.log('File:', file ? `${file.originalname} (${file.size} bytes)` : 'No file');
    
    try {
      const result = await this.postService.createPostWithCloudinary(body, file);
      return { success: true, data: result };
    } catch (error) {
      console.error('[PostController] Error in createPost:', error);
      throw error;
    }
  }

  @Post('create_post_multi')
  @UseInterceptors(
    FilesInterceptor('media', 10, {
      storage: memoryStorage(),
    }),
  )
  async createPostMulti(@Body() body: any, @UploadedFiles() files: Express.Multer.File[]) {
    console.log('--- [PostController] New create_post_multi request ---');
    console.log('Files count:', files ? files.length : 0);
    
    try {
      const result = await this.postService.createPostMultiWithCloudinary(body, files || []);
      return { success: true, data: result };
    } catch (error) {
      console.error('[PostController] Error in createPostMulti:', error);
      throw error;
    }
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

  @Post('mark_view')
  async markView(@Body() body: any) {
    const { user_id, post_id } = body;
    const result = await this.postService.markView(user_id, post_id);
    return { success: true, ...result };
  }

  @Post('delete_post')
  async deletePost(@Body() body: any) {
    const { user_id, post_id } = body;
    const result = await this.postService.deletePost(user_id, post_id);
    return { success: true, ...result };
  }
}
