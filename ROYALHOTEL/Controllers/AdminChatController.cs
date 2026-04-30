using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using ROYALHOTEL.DTOs;
using ROYALHOTEL.Services.Chat;

namespace ROYALHOTEL.Controllers
{
    /// <summary>
    /// Admin controller for managing escalated chat conversations
    /// Validates: Requirements 9.2, 17.5
    /// </summary>
    public class AdminChatController : Controller
    {
        private readonly IChatService _chatService;
        private readonly RoyalHotelDbContext _context;
        private readonly ILogger<AdminChatController> _logger;
        private readonly MessageCleanupService? _messageCleanupService;

        public AdminChatController(
            IChatService chatService,
            RoyalHotelDbContext context,
            ILogger<AdminChatController> logger,
            IServiceProvider serviceProvider)
        {
            _chatService = chatService;
            _context = context;
            _logger = logger;
            
            // Try to get MessageCleanupService for manual trigger (optional)
            try
            {
                _messageCleanupService = serviceProvider.GetService<MessageCleanupService>();
            }
            catch
            {
                _messageCleanupService = null;
            }
        }

        /// <summary>
        /// Check if current user is admin using session-based auth
        /// </summary>
        private bool IsAdmin()
        {
            var role = HttpContext.Session.GetString("USER_ROLE");
            return role != null && role.ToLower() == "admin";
        }

        /// <summary>
        /// Sub-task 8.2: Display list of escalated conversations
        /// Validates: Requirements 9.2, 9.3
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> Index()
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            try
            {
                // Query conversations with Status="EscalatedToAdmin" or "AnsweredByAdmin" ordered by UpdatedAt descending
                var escalatedConversations = await _context.ChatConversations
                    .Include(c => c.Account)
                    .Where(c => c.Status == "EscalatedToAdmin" || c.Status == "AnsweredByAdmin")
                    .OrderByDescending(c => c.UpdatedAt)
                    .ToListAsync();

                _logger.LogInformation(
                    "Admin viewing escalated conversations. Count: {Count}",
                    escalatedConversations.Count);

                return View(escalatedConversations);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading escalated conversations");
                TempData["Error"] = "Không thể tải danh sách cuộc hội thoại";
                return View(new List<Models.ChatConversation>());
            }
        }

        /// <summary>
        /// API endpoint for polling new escalated conversations
        /// GET /AdminChat/PollNewConversations
        /// Returns: JSON with hasNew flag and conversation count
        /// </summary>
        [HttpGet]
        [Route("AdminChat/PollNewConversations")]
        public async Task<IActionResult> PollNewConversations([FromQuery] DateTime? lastCheck)
        {
            if (!IsAdmin())
            {
                return Unauthorized(new { hasNew = false, count = 0 });
            }

            try
            {
                // If no lastCheck provided, use 1 minute ago
                var checkTime = lastCheck ?? DateTime.UtcNow.AddMinutes(-1);

                // Query conversations that were escalated or updated after lastCheck
                var newConversations = await _context.ChatConversations
                    .Where(c => (c.Status == "EscalatedToAdmin" || c.Status == "AnsweredByAdmin") 
                             && c.UpdatedAt > checkTime)
                    .OrderByDescending(c => c.UpdatedAt)
                    .Select(c => new
                    {
                        c.Id,
                        c.ConversationCode,
                        c.GuestName,
                        c.Status,
                        c.UpdatedAt
                    })
                    .ToListAsync();

                var hasNew = newConversations.Count > 0;

                _logger.LogInformation(
                    "Poll check: {Count} new/updated conversations since {LastCheck}",
                    newConversations.Count, checkTime);

                return Ok(new
                {
                    hasNew = hasNew,
                    count = newConversations.Count,
                    conversations = newConversations,
                    serverTime = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error polling new conversations");
                return StatusCode(500, new { hasNew = false, count = 0, error = "Internal server error" });
            }
        }

        /// <summary>
        /// API endpoint for polling new messages in a specific conversation
        /// GET /AdminChat/PollNewMessages/{conversationId}
        /// Returns: JSON with hasNew flag and new messages
        /// </summary>
        [HttpGet]
        [Route("AdminChat/PollNewMessages/{conversationId}")]
        public async Task<IActionResult> PollNewMessages(int conversationId, [FromQuery] DateTime? lastCheck)
        {
            if (!IsAdmin())
            {
                return Unauthorized(new { hasNew = false, messages = new List<object>() });
            }

            try
            {
                // If no lastCheck provided, use 1 minute ago
                var checkTime = lastCheck ?? DateTime.UtcNow.AddMinutes(-1);

                // Query new messages after lastCheck
                var newMessages = await _context.ChatMessages
                    .Where(m => m.ConversationId == conversationId && m.CreatedAt > checkTime)
                    .OrderBy(m => m.CreatedAt)
                    .Select(m => new
                    {
                        m.Id,
                        m.SenderType,
                        m.MessageText,
                        m.CreatedAt
                    })
                    .ToListAsync();

                var hasNew = newMessages.Count > 0;

                _logger.LogInformation(
                    "Poll check: {Count} new messages in conversation {ConversationId} since {LastCheck}",
                    newMessages.Count, conversationId, checkTime);

                return Ok(new
                {
                    hasNew = hasNew,
                    count = newMessages.Count,
                    messages = newMessages,
                    serverTime = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error polling new messages for conversation {ConversationId}", conversationId);
                return StatusCode(500, new { hasNew = false, messages = new List<object>(), error = "Internal server error" });
            }
        }

        /// <summary>
        /// Sub-task 8.3: Display conversation detail with full history
        /// Validates: Requirements 9.4
        /// </summary>
        [HttpGet]
        [Route("AdminChat/ViewConversation/{conversationId}")]
        public async Task<IActionResult> ViewConversation(int conversationId)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            try
            {
                // Get conversation
                var conversation = await _context.ChatConversations
                    .Include(c => c.Account)
                    .FirstOrDefaultAsync(c => c.Id == conversationId);

                if (conversation == null)
                {
                    _logger.LogWarning("Conversation {ConversationId} not found", conversationId);
                    TempData["Error"] = "Không tìm thấy cuộc hội thoại";
                    return RedirectToAction("Index");
                }

                // Get conversation history (pass null for userId to bypass auth check for admin)
                var messages = await _chatService.GetConversationHistoryAsync(conversationId, null);

                ViewBag.Conversation = conversation;
                ViewBag.Messages = messages;

                _logger.LogInformation(
                    "Admin viewing conversation {ConversationId} with {MessageCount} messages",
                    conversationId, messages.Count);

                return View();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading conversation {ConversationId}", conversationId);
                TempData["Error"] = "Không thể tải cuộc hội thoại";
                return RedirectToAction("Index");
            }
        }

        /// <summary>
        /// Sub-task 8.4: Handle admin response to escalated conversation
        /// Validates: Requirements 10.1, 10.2, 10.3, 10.4
        /// </summary>
        [HttpPost]
        [Route("AdminChat/Respond")]
        public async Task<IActionResult> Respond([FromBody] AdminResponseRequest request)
        {
            if (!IsAdmin())
            {
                return Unauthorized(new { success = false, message = "Unauthorized" });
            }

            try
            {
                // Validate request
                if (string.IsNullOrWhiteSpace(request.ResponseText))
                {
                    return BadRequest(new { success = false, message = "Response text is required" });
                }

                // Get conversation
                var conversation = await _context.ChatConversations
                    .FirstOrDefaultAsync(c => c.Id == request.ConversationId);

                if (conversation == null)
                {
                    return NotFound(new { success = false, message = "Conversation not found" });
                }

                // Save admin message to ChatMessages table with SenderType=Admin
                var adminMessage = new Models.ChatMessage
                {
                    ConversationId = request.ConversationId,
                    SenderType = "Admin",
                    MessageText = request.ResponseText,
                    IsEscalationMessage = false,
                    CreatedAt = DateTime.UtcNow
                };

                _context.ChatMessages.Add(adminMessage);

                // Update conversation Status to "AnsweredByAdmin"
                conversation.Status = "AnsweredByAdmin";
                conversation.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                _logger.LogInformation(
                    "Admin responded to conversation {ConversationId}. Status updated to AnsweredByAdmin",
                    request.ConversationId);

                return Ok(new { success = true, message = "Response sent successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error responding to conversation {ConversationId}", request.ConversationId);
                return StatusCode(500, new { success = false, message = "Internal server error" });
            }
        }

        /// <summary>
        /// API endpoint to get all messages for a conversation (for Messenger-style UI)
        /// GET /AdminChat/GetMessages/{conversationId}
        /// Returns JSON array of messages ordered by CreatedAt
        /// </summary>
        [HttpGet]
        [Route("AdminChat/GetMessages/{conversationId}")]
        public async Task<IActionResult> GetMessages(int conversationId)
        {
            if (!IsAdmin())
            {
                return Unauthorized(new { messages = new List<object>() });
            }

            try
            {
                var conversation = await _context.ChatConversations
                    .Include(c => c.Account)
                    .FirstOrDefaultAsync(c => c.Id == conversationId);

                if (conversation == null)
                {
                    return NotFound(new { messages = new List<object>(), error = "Conversation not found" });
                }

                var messages = await _context.ChatMessages
                    .Where(m => m.ConversationId == conversationId)
                    .OrderBy(m => m.CreatedAt)
                    .Select(m => new
                    {
                        m.Id,
                        m.SenderType,
                        m.MessageText,
                        m.CreatedAt
                    })
                    .ToListAsync();

                // Build display name: prefer Account.FullName, fallback to GuestName
                var displayName = conversation.Account?.FullName
                    ?? conversation.GuestName
                    ?? "Anonymous Guest";

                return Ok(new
                {
                    messages,
                    displayName,
                    guestPhone = conversation.GuestPhone,
                    status = conversation.Status,
                    serverTime = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting messages for conversation {ConversationId}", conversationId);
                return StatusCode(500, new { messages = new List<object>(), error = "Internal server error" });
            }
        }

        /// <summary>
        /// Manual trigger for message cleanup (for testing purposes)
        /// DELETE /AdminChat/CleanupMessages
        /// </summary>
        [HttpDelete]
        [Route("AdminChat/CleanupMessages")]
        public async Task<IActionResult> CleanupMessages()
        {
            if (!IsAdmin())
            {
                return Unauthorized(new { success = false, message = "Unauthorized" });
            }

            try
            {
                // Calculate cutoff date (start of today in UTC)
                var todayStart = DateTime.UtcNow.Date;

                // Query messages created before today
                var oldMessages = await _context.ChatMessages
                    .Where(m => m.CreatedAt < todayStart)
                    .ToListAsync();

                var messageCount = oldMessages.Count;

                if (messageCount == 0)
                {
                    _logger.LogInformation("Manual cleanup: No old messages found to delete");
                    return Ok(new 
                    { 
                        success = true, 
                        message = "No old messages found to delete",
                        messagesDeleted = 0,
                        cutoffDate = todayStart
                    });
                }

                // Delete messages
                _context.ChatMessages.RemoveRange(oldMessages);
                await _context.SaveChangesAsync();

                _logger.LogInformation(
                    "Manual cleanup: Deleted {Count} messages created before {CutoffDate}",
                    messageCount,
                    todayStart);

                return Ok(new 
                { 
                    success = true, 
                    message = $"Successfully deleted {messageCount} messages",
                    messagesDeleted = messageCount,
                    cutoffDate = todayStart
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during manual message cleanup");
                return StatusCode(500, new { success = false, message = "Internal server error" });
            }
        }

        /// <summary>
        /// API endpoint to mark a conversation as read (AnsweredByAdmin)
        /// POST /AdminChat/MarkAsRead/{id}
        /// </summary>
        [HttpPost]
        [Route("AdminChat/MarkAsRead/{id}")]
        public async Task<IActionResult> MarkAsRead(int id)
        {
            if (!IsAdmin())
            {
                return Unauthorized(new { success = false, message = "Unauthorized" });
            }

            try
            {
                var conversation = await _context.ChatConversations.FindAsync(id);
                if (conversation == null)
                {
                    return NotFound(new { success = false, message = "Conversation not found" });
                }

                conversation.Status = "AnsweredByAdmin";
                conversation.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return Ok(new { success = true });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error marking conversation {ConversationId} as read", id);
                return StatusCode(500, new { success = false, message = "Internal server error" });
            }
        }

        /// <summary>
        /// API endpoint to close a conversation
        /// POST /AdminChat/CloseConversation/{id}
        /// </summary>
        [HttpPost]
        [Route("AdminChat/CloseConversation/{id}")]
        public async Task<IActionResult> CloseConversation(int id)
        {
            if (!IsAdmin())
            {
                return Unauthorized(new { success = false, message = "Unauthorized" });
            }

            try
            {
                var conversation = await _context.ChatConversations.FindAsync(id);
                if (conversation == null)
                {
                    return NotFound(new { success = false, message = "Conversation not found" });
                }

                conversation.Status = "Closed";
                conversation.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                _logger.LogInformation("Admin closed conversation {ConversationId}", id);

                return Ok(new { success = true });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error closing conversation {ConversationId}", id);
                return StatusCode(500, new { success = false, message = "Internal server error" });
            }
        }

        /// <summary>
        /// API endpoint to delete a conversation and its messages
        /// POST /AdminChat/DeleteConversation/{id}
        /// </summary>
        [HttpPost]
        [Route("AdminChat/DeleteConversation/{id}")]
        public async Task<IActionResult> DeleteConversation(int id)
        {
            if (!IsAdmin())
            {
                return Unauthorized(new { success = false, message = "Unauthorized" });
            }

            try
            {
                var conversation = await _context.ChatConversations.FindAsync(id);
                if (conversation == null)
                {
                    return NotFound(new { success = false, message = "Conversation not found" });
                }

                _context.ChatConversations.Remove(conversation);
                await _context.SaveChangesAsync();

                _logger.LogInformation("Deleted conversation {ConversationId}", id);

                return Ok(new { success = true });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting conversation {ConversationId}", id);
                return StatusCode(500, new { success = false, message = "Internal server error" });
            }
        }

        /// <summary>
        /// API endpoint for real-time unread count badge in admin nav
        /// GET /AdminChat/UnreadCount
        /// Returns count of conversations with status EscalatedToAdmin
        /// </summary>
        [HttpGet]
        [Route("AdminChat/UnreadCount")]
        public async Task<IActionResult> UnreadCount()
        {
            if (!IsAdmin())
                return Unauthorized(new { count = 0 });

            try
            {
                var count = await _context.ChatConversations
                    .CountAsync(c => c.Status == "EscalatedToAdmin");
                return Ok(new { count });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting unread count");
                return StatusCode(500, new { count = 0 });
            }
        }

        /// <summary>
        /// API endpoint for user-side real-time polling of Admin replies.
        /// No auth required – conversationId acts as the access token (stored in user's sessionStorage).
        /// GET /AdminChat/PollAdminReplies/{conversationId}?since=ISO8601
        /// </summary>
        [HttpGet]
        [Route("AdminChat/PollAdminReplies/{conversationId}")]
        public async Task<IActionResult> PollAdminReplies(int conversationId, [FromQuery] string? since)
        {
            try
            {
                var sinceTime = DateTime.UtcNow.AddHours(-24); // default: last 24h
                if (!string.IsNullOrEmpty(since) &&
                    DateTime.TryParse(since, null,
                        System.Globalization.DateTimeStyles.RoundtripKind, out var parsed))
                {
                    sinceTime = parsed;
                }

                // Get conversation status
                var conversation = await _context.ChatConversations.FindAsync(conversationId);
                var status = conversation?.Status ?? "Closed";

                var messages = await _context.ChatMessages
                    .Where(m => m.ConversationId == conversationId
                             && m.SenderType == "Admin"
                             && m.CreatedAt > sinceTime)
                    .OrderBy(m => m.CreatedAt)
                    .Select(m => new
                    {
                        senderType  = m.SenderType,
                        messageText = m.MessageText,
                        createdAt   = m.CreatedAt
                    })
                    .ToListAsync();

                return Ok(new
                {
                    messages,
                    status,
                    serverTime = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error polling admin replies for conversation {Id}", conversationId);
                return StatusCode(500, new { messages = new List<object>(), status = "Closed", serverTime = DateTime.UtcNow });
            }
        }
    }
}
