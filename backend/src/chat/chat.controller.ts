import { Controller, Get, Post, Body, Query } from '@nestjs/common';
import { ChatService } from './chat.service';

@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get('get_conversations')
  async getConversations(@Query('user_id') userId: string) {
    const result = await this.chatService.getConversations(parseInt(userId));
    return { success: true, data: result };
  }

  @Get('get_messages')
  async getMessages(@Query('user_id') userId: string, @Query('other_id') otherId: string) {
    const result = await this.chatService.getMessages(parseInt(userId), parseInt(otherId));
    return { success: true, data: result };
  }

  @Post('send_message')
  async sendMessage(@Body() body: any) {
    const { sender_id, receiver_id, content } = body;
    const result = await this.chatService.sendMessage(parseInt(sender_id), parseInt(receiver_id), content);
    return { success: true, data: result };
  }
}
