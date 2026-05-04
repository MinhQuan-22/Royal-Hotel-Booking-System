using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ROYALHOTEL.DTOs;
using ROYALHOTEL.Services.Chat;
using System.Security.Claims;
using System.Text.RegularExpressions;

namespace ROYALHOTEL.Controllers;

/// <summary>
/// REST API Controller for chat operations
/// Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5, 8.4, 20.3, 20.4, 1.3, 17.4, 15.3
/// </summary>
[ApiController]
[Route("api/chat")]
public class ChatController : ControllerBase
{
    private readonly IChatService _chatService;
    private readonly ILogger<ChatController> _logger;

    public ChatController(IChatService chatService, ILogger<ChatController> logger)
    {
        _chatService = chatService;
        _logger = logger;
    }

    /// <summary>
    /// Sub-task 6.2: Send a message to the chat system
    /// POST /api/chat/send
    /// Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5
    /// </summary>
    [HttpPost("send")]
    public async Task<IActionResult> SendMessage([FromBody] SendMessageRequest request)
    {
        try
        {
            // Validate MessageText is not empty and does not exceed 2000 characters
            if (string.IsNullOrWhiteSpace(request.MessageText))
            {
                _logger.LogWarning("SendMessage called with empty MessageText");
                return BadRequest(new { error = "Câu hỏi không hợp lệ" });
            }

            if (request.MessageText.Length > 2000)
            {
                _logger.LogWarning("SendMessage called with MessageText exceeding 2000 characters");
                return BadRequest(new { error = "Câu hỏi không hợp lệ" });
            }

            // Validate guest phone if provided
            if (!string.IsNullOrEmpty(request.GuestPhone))
            {
                if (!IsValidPhoneNumber(request.GuestPhone))
                {
                    _logger.LogWarning("SendMessage called with invalid GuestPhone: {GuestPhone}", request.GuestPhone);
                    return BadRequest(new { error = "Số điện thoại phải có 10 chữ số và bắt đầu bằng số 0" });
                }
            }

            // Validate guest name if provided
            if (!string.IsNullOrEmpty(request.GuestName))
            {
                if (!IsValidName(request.GuestName))
                {
                    _logger.LogWarning("SendMessage called with invalid GuestName");
                    return BadRequest(new { error = "Họ tên phải có ít nhất 2 ký tự và không vượt quá 200 ký tự" });
                }
            }

            // Extract userId from Session
            int? userId = HttpContext.Session.GetInt32("USER_ID");

            // Call ChatService.ProcessQuestionAsync
            var response = await _chatService.ProcessQuestionAsync(request, userId);

            // Return OkObjectResult with ChatResponse
            return Ok(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing chat message");
            return StatusCode(500, new { error = "Đã xảy ra lỗi, vui lòng thử lại" });
        }
    }

    /// <summary>
    /// Validate phone number format (10 digits starting with 0)
    /// </summary>
    private bool IsValidPhoneNumber(string phone)
    {
        return Regex.IsMatch(phone, @"^0\d{9}$");
    }

    /// <summary>
    /// Validate name length (2-200 characters)
    /// </summary>
    private bool IsValidName(string name)
    {
        var trimmed = name?.Trim() ?? "";
        return trimmed.Length >= 2 && trimmed.Length <= 200;
    }

    /// <summary>
    /// Sub-task 6.3: Escalate a conversation to admin
    /// POST /api/chat/escalate
    /// Validates: Requirements 8.4
    /// </summary>
    [HttpPost("escalate")]
    public async Task<IActionResult> EscalateConversation([FromBody] EscalateRequest request)
    {
        try
        {
            if (request.ConversationId <= 0)
            {
                _logger.LogWarning("EscalateConversation called with invalid ConversationId: {ConversationId}", request.ConversationId);
                return BadRequest(new { error = "Conversation ID không hợp lệ" });
            }

            var success = await _chatService.EscalateConversationAsync(request.ConversationId, request.Reason);

            if (!success)
            {
                _logger.LogWarning("Failed to escalate conversation {ConversationId}", request.ConversationId);
                return NotFound(new { error = "Không tìm thấy cuộc hội thoại" });
            }

            return Ok(new { message = "Cuộc hội thoại đã được chuyển đến admin" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error escalating conversation {ConversationId}", request.ConversationId);
            return StatusCode(500, new { error = "Đã xảy ra lỗi, vui lòng thử lại" });
        }
    }

    /// <summary>
    /// Sub-task 6.4: Close a conversation
    /// POST /api/chat/close
    /// Validates: Requirements 20.3, 20.4
    /// </summary>
    [HttpPost("close")]
    public async Task<IActionResult> CloseConversation([FromBody] CloseConversationRequest request)
    {
        try
        {
            if (request.ConversationId <= 0)
            {
                _logger.LogWarning("CloseConversation called with invalid ConversationId: {ConversationId}", request.ConversationId);
                return BadRequest(new { error = "Conversation ID không hợp lệ" });
            }

            var success = await _chatService.CloseConversationAsync(request.ConversationId);

            if (!success)
            {
                _logger.LogWarning("Failed to close conversation {ConversationId}", request.ConversationId);
                return NotFound(new { error = "Không tìm thấy cuộc hội thoại" });
            }

            return Ok(new { message = "Cuộc hội thoại đã được đóng" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error closing conversation {ConversationId}", request.ConversationId);
            return StatusCode(500, new { error = "Đã xảy ra lỗi, vui lòng thử lại" });
        }
    }

    /// <summary>
    /// Sub-task 6.5: Get conversation history
    /// GET /api/chat/history/{conversationId}
    /// Validates: Requirements 1.3, 17.4
    /// </summary>
    [HttpGet("history/{conversationId}")]
    public async Task<IActionResult> GetConversationHistory(int conversationId)
    {
        try
        {
            if (conversationId <= 0)
            {
                _logger.LogWarning("GetConversationHistory called with invalid conversationId: {ConversationId}", conversationId);
                return BadRequest(new { error = "Conversation ID không hợp lệ" });
            }

            // Extract userId from Session
            int? userId = HttpContext.Session.GetInt32("USER_ID");

            if (userId == null)
            {
                _logger.LogWarning("GetConversationHistory called without valid user ID");
                return Unauthorized(new { error = "Bạn cần đăng nhập để xem lịch sử" });
            }

            // Call ChatService.GetConversationHistoryAsync
            var messages = await _chatService.GetConversationHistoryAsync(conversationId, userId);

            // Return 403 Forbidden if user does not own conversation (empty list returned)
            if (messages.Count == 0)
            {
                // Check if conversation exists at all
                var allMessages = await _chatService.GetConversationHistoryAsync(conversationId, null);
                if (allMessages.Count > 0)
                {
                    _logger.LogWarning("User {UserId} attempted unauthorized access to conversation {ConversationId}", userId, conversationId);
                    return StatusCode(403, new { error = "Bạn không có quyền truy cập" });
                }
                else
                {
                    return NotFound(new { error = "Không tìm thấy cuộc hội thoại" });
                }
            }

            return Ok(messages);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving conversation history for {ConversationId}", conversationId);
            return StatusCode(500, new { error = "Đã xảy ra lỗi, vui lòng thử lại" });
        }
    }

    /// <summary>
    /// Sub-task 6.6: Get user's conversations
    /// GET /api/chat/conversations
    /// Validates: Requirements 15.3
    /// </summary>
    [HttpGet("conversations")]
    public async Task<IActionResult> GetUserConversations()
    {
        try
        {
            // Extract userId from Session
            int? userId = HttpContext.Session.GetInt32("USER_ID");

            if (userId == null)
            {
                _logger.LogWarning("GetUserConversations called without valid user ID");
                return Unauthorized(new { error = "Bạn cần đăng nhập để xem danh sách hội thoại" });
            }

            // Call ChatService.GetUserConversationsAsync
            var conversations = await _chatService.GetUserConversationsAsync(userId.Value);

            return Ok(conversations);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving user conversations");
            return StatusCode(500, new { error = "Đã xảy ra lỗi, vui lòng thử lại" });
        }
    }
}
