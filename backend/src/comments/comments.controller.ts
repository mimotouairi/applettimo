import { Controller, Get, Post, Body, Query, BadRequestException } from '@nestjs/common';
import { CommentService } from './comments.service';

@Controller('comments')
export class CommentController {
  constructor(private readonly commentService: CommentService) {}

  @Get('get_comments')
  async getComments(@Query('post_id') postId: string) {
    if (!postId) throw new BadRequestException('Post ID is required');
    const result = await this.commentService.getComments(parseInt(postId));
    return { success: true, data: result };
  }

  @Post('add_comment')
  async addComment(@Body() body: any) {
    const { post_id, user_id, comment } = body;
    const result = await this.commentService.addComment(
      parseInt(post_id),
      parseInt(user_id),
      comment,
    );
    return { success: true, data: result };
  }
}
