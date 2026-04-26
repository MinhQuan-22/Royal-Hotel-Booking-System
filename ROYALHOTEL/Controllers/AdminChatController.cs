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

        public AdminChatController(
            IChatService chatService,
            RoyalHotelDbContext context,
            ILogger<AdminChatController> logger)
        {
            _chatService = chatService;
            _context = context;
            _logger = logger;
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
                // Query conversations with Status="EscalatedToAdmin" ordered by CreatedAt descending
                var escalatedConversations = await _context.ChatConversations
                    .Include(c => c.Account)
                    .Where(c => c.Status == "EscalatedToAdmin")
                    .OrderByDescending(c => c.CreatedAt)
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
    }
}
