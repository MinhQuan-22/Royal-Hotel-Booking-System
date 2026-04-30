/**
 * Chat Widget - AI Live Chat Support
 * Handles user interactions with the chat widget
 */

/**
 * Guest Info Form Component
 * Handles guest information collection before chat
 */
class GuestInfoForm {
  constructor(chatWidget) {
    this.chatWidget = chatWidget;
    this.formContainer = document.getElementById("chat-guest-form");
    this.nameInput = document.getElementById("guest-name");
    this.phoneInput = document.getElementById("guest-phone");
    this.nameError = document.getElementById("guest-name-error");
    this.phoneError = document.getElementById("guest-phone-error");
    this.submitBtn = document.getElementById("guest-form-submit");

    this.init();
  }

  init() {
    // Add input event listeners for real-time validation
    this.nameInput.addEventListener("input", () => this.validateName());
    this.phoneInput.addEventListener("input", () => this.validatePhone());
    this.submitBtn.addEventListener("click", () => this.submit());

    // Allow Enter key to submit
    this.phoneInput.addEventListener("keypress", (e) => {
      if (e.key === "Enter") {
        e.preventDefault();
        this.submit();
      }
    });
  }

  show() {
    this.formContainer.style.display = "block";
    this.chatWidget.messagesContainer.style.display = "none";
    this.chatWidget.inputWrapper.style.display = "none";
    this.chatWidget.escalationSection.style.display = "none";
    this.nameInput.focus();
  }

  hide() {
    this.formContainer.style.display = "none";
    this.chatWidget.messagesContainer.style.display = "flex";
    this.chatWidget.inputWrapper.style.display = "flex";
  }

  validateName() {
    const name = this.nameInput.value;
    const trimmed = name.trim();

    if (!name || trimmed.length === 0) {
      this.nameError.textContent = "Vui lòng nhập họ tên";
      this.nameInput.classList.add("error");
      return false;
    }

    if (trimmed.length < 2) {
      this.nameError.textContent = "Họ tên phải có ít nhất 2 ký tự";
      this.nameInput.classList.add("error");
      return false;
    }

    if (name.length > 200) {
      this.nameError.textContent = "Họ tên không được vượt quá 200 ký tự";
      this.nameInput.classList.add("error");
      return false;
    }

    this.nameError.textContent = "";
    this.nameInput.classList.remove("error");
    return true;
  }

  validatePhone() {
    const phone = this.phoneInput.value;

    if (!phone || phone.trim().length === 0) {
      this.phoneError.textContent = "Vui lòng nhập số điện thoại";
      this.phoneInput.classList.add("error");
      return false;
    }

    const phonePattern = /^0\d{9}$/;
    if (!phonePattern.test(phone)) {
      this.phoneError.textContent =
        "Số điện thoại phải có 10 chữ số và bắt đầu bằng số 0";
      this.phoneInput.classList.add("error");
      return false;
    }

    this.phoneError.textContent = "";
    this.phoneInput.classList.remove("error");
    return true;
  }

  validate() {
    const nameValid = this.validateName();
    const phoneValid = this.validatePhone();
    return nameValid && phoneValid;
  }

  submit() {
    if (!this.validate()) {
      return;
    }

    const guestData = this.getGuestData();
    this.chatWidget.saveGuestInfoToSession(guestData.name, guestData.phone);
    this.chatWidget.guestName = guestData.name;
    this.chatWidget.guestPhone = guestData.phone;
    this.hide();

    // Show welcome message
    this.chatWidget.showWelcomeMessage();
  }

  getGuestData() {
    return {
      name: this.nameInput.value.trim(),
      phone: this.phoneInput.value.trim(),
    };
  }
}

class ChatWidget {
  constructor() {
    this.conversationId = null;
    this.isOpen = false;
    this.isProcessing = false;
    this.guestName = null;
    this.guestPhone = null;
    this.isAuthenticated = false;
    this.adminPollingTimer = null;   // polls for admin replies after escalation
    this.lastPolledMsgCount = 0;    // tracks how many messages have been shown

    // DOM elements
    this.widget = document.getElementById("chat-widget");
    this.toggleBtn = document.getElementById("chat-widget-toggle");
    this.closeBtn = document.querySelector(".chat-widget__close");
    this.messagesContainer = document.getElementById("chat-messages");
    this.inputField = document.getElementById("chat-input");
    this.sendBtn = document.getElementById("chat-send-btn");
    this.typingIndicator = document.getElementById("chat-typing");
    this.escalationSection = document.getElementById("chat-escalation");
    this.escalationBtn = document.getElementById("chat-escalation-btn");
    this.inputWrapper = document.querySelector(".chat-widget__input-wrapper");

    // Guest info form
    this.guestInfoForm = new GuestInfoForm(this);

    this.init();
  }

  init() {
    // Check if widget should render based on user role and page URL
    if (!this.shouldRenderWidget()) {
      return;
    }

    // Load conversation ID from sessionStorage
    this.conversationId = sessionStorage.getItem("chatConversationId");

    // Check authentication
    this.isAuthenticated = this.checkAuthentication();

    // Load guest info from session if not authenticated
    if (!this.isAuthenticated) {
      const hasGuestInfo = this.loadGuestInfoFromSession();
      if (!hasGuestInfo) {
        // Will show guest form when widget opens
        this.shouldShowGuestForm = true;
      }
    }

    // Event listeners
    this.toggleBtn.addEventListener("click", () => this.toggleWidget());
    this.closeBtn.addEventListener("click", () => this.closeWidget());
    this.sendBtn.addEventListener("click", () => this.sendMessage());
    this.inputField.addEventListener("keypress", (e) => {
      if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault();
        this.sendMessage();
      }
    });
    this.escalationBtn.addEventListener("click", () => this.escalateToAdmin());

    // Load conversation history for authenticated users
    if (this.isAuthenticated) {
      this.loadConversationHistory();
    }
  }

  /**
   * Determine if chat widget should render based on user role and page URL
   * Requirements 4.1, 4.2, 4.3, 4.4, 4.5, 4.6
   */
  shouldRenderWidget() {
    const userRole = this.getUserRole();
    const isAdminPage = this.isAdminPage();

    // Admin users should NEVER see the chat widget on any page
    if (userRole === "Admin") {
      return false;
    }

    // Regular users and guests should not see widget on admin pages
    if (isAdminPage) {
      return false;
    }

    // Show widget on public pages for regular users and guests
    return true;
  }

  /**
   * Get user role from cookies or session
   * Returns: "Admin", "User", or null for guests
   */
  getUserRole() {
    // Read role from server-injected meta tag (set in _Layout.cshtml via Session)
    const roleMeta = document.querySelector('meta[name="user-role"]');
    const role = roleMeta?.content ?? "";
    return role.length > 0 ? role : null;
  }

  isAdminPage() {
    return window.location.pathname.startsWith("/Admin");
  }

  checkAuthentication() {
    // Read auth status from server-injected meta tag (set in _Layout.cshtml via Session)
    // NOTE: .AspNetCore.Session cookie exists for ALL visitors (including guests), so
    // we must NOT rely on it to detect login status.
    const authMeta = document.querySelector('meta[name="user-authenticated"]');
    return authMeta?.content === "true";
  }

  loadGuestInfoFromSession() {
    try {
      const name = sessionStorage.getItem("chatGuestName");
      const phone = sessionStorage.getItem("chatGuestPhone");

      if (name && phone) {
        this.guestName = name;
        this.guestPhone = phone;
        return true;
      }
      return false;
    } catch (e) {
      console.error("SessionStorage unavailable:", e);
      return false;
    }
  }

  saveGuestInfoToSession(name, phone) {
    try {
      sessionStorage.setItem("chatGuestName", name);
      sessionStorage.setItem("chatGuestPhone", phone);
    } catch (e) {
      console.error("SessionStorage unavailable:", e);
    }
  }

  showWelcomeMessage() {
    const welcomeDiv = document.createElement("div");
    welcomeDiv.className = "chat-widget__welcome";
    welcomeDiv.innerHTML = `
      <p>Xin chào! Tôi có thể giúp gì cho bạn?</p>
      <p class="chat-widget__welcome-hint">Hỏi về tiện ích khách sạn, phòng, chính sách...</p>
    `;
    this.messagesContainer.appendChild(welcomeDiv);
  }

  toggleWidget() {
    if (this.isOpen) {
      this.closeWidget();
    } else {
      this.openWidget();
    }
  }

  openWidget() {
    this.widget.style.display = "flex";
    this.isOpen = true;

    // Show guest form if needed
    if (
      !this.isAuthenticated &&
      !this.guestName &&
      !this.guestPhone &&
      this.shouldShowGuestForm
    ) {
      this.guestInfoForm.show();
    } else {
      this.inputField.focus();
    }

    // Scroll to bottom
    setTimeout(() => {
      this.scrollToBottom();
    }, 100);
  }

  closeWidget() {
    this.widget.style.display = "none";
    this.isOpen = false;
  }

  async sendMessage() {
    const messageText = this.inputField.value.trim();

    // Validation
    if (!messageText) {
      return;
    }

    if (messageText.length > 2000) {
      this.displayError("Tin nhắn quá dài. Vui lòng nhập tối đa 2000 ký tự.");
      return;
    }

    if (this.isProcessing) {
      return;
    }

    // Clear input
    this.inputField.value = "";

    // Display user message immediately
    this.displayMessage("User", messageText, new Date());

    // Show typing indicator
    this.showTypingIndicator();

    // Disable input
    this.isProcessing = true;
    this.sendBtn.disabled = true;
    this.inputField.disabled = true;

    try {
      // Prepare request
      const requestData = {
        conversationId: this.conversationId,
        messageText: messageText,
      };

      // Include guest data only for first message of new conversation
      if (!this.conversationId && !this.isAuthenticated) {
        if (this.guestName) {
          requestData.guestName = this.guestName;
        }
        if (this.guestPhone) {
          requestData.guestPhone = this.guestPhone;
        }
      }

      // Make API call
      const response = await fetch("/api/chat/send", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(requestData),
      });

      if (!response.ok) {
        if (response.status === 429) {
          throw new Error("Quá nhiều yêu cầu, vui lòng thử lại sau.");
        }
        throw new Error("Không thể gửi tin nhắn. Vui lòng thử lại.");
      }

      const data = await response.json();

      // Save conversation ID
      if (data.conversationId) {
        this.conversationId = data.conversationId;
        sessionStorage.setItem("chatConversationId", data.conversationId);
      }

      // Hide typing indicator
      this.hideTypingIndicator();

      // Display AI response
      this.displayMessage("AI", data.responseText, new Date(data.timestamp));

      // Show escalation button if needed
      if (data.showContactAdmin) {
        this.showEscalationButton();
      }
    } catch (error) {
      console.error("Error sending message:", error);
      this.hideTypingIndicator();
      this.displayError(error.message || "Đã xảy ra lỗi. Vui lòng thử lại.");
    } finally {
      // Re-enable input
      this.isProcessing = false;
      this.sendBtn.disabled = false;
      this.inputField.disabled = false;
      this.inputField.focus();
    }
  }

  displayMessage(senderType, messageText, timestamp) {
    const messageDiv = document.createElement("div");
    messageDiv.className = `chat-widget__message chat-widget__message--${senderType.toLowerCase()}`;

    const bubbleDiv = document.createElement("div");
    bubbleDiv.className = "chat-widget__message-bubble";
    bubbleDiv.textContent = messageText;

    const metaDiv = document.createElement("div");
    metaDiv.className = "chat-widget__message-meta";

    const senderSpan = document.createElement("span");
    senderSpan.className = "chat-widget__message-sender";
    senderSpan.textContent = this.getSenderLabel(senderType);

    const timeSpan = document.createElement("span");
    timeSpan.className = "chat-widget__message-time";
    timeSpan.textContent = this.formatTime(timestamp);

    metaDiv.appendChild(senderSpan);
    metaDiv.appendChild(document.createTextNode("•"));
    metaDiv.appendChild(timeSpan);

    messageDiv.appendChild(bubbleDiv);
    messageDiv.appendChild(metaDiv);

    this.messagesContainer.appendChild(messageDiv);
    this.scrollToBottom();
  }

  displayError(errorMessage) {
    const errorDiv = document.createElement("div");
    errorDiv.className = "chat-widget__error";
    errorDiv.textContent = errorMessage;

    this.messagesContainer.appendChild(errorDiv);
    this.scrollToBottom();

    // Auto-remove after 5 seconds
    setTimeout(() => {
      errorDiv.remove();
    }, 5000);
  }

  showTypingIndicator() {
    this.typingIndicator.style.display = "inline-flex";
    this.messagesContainer.appendChild(this.typingIndicator);
    this.scrollToBottom();
  }

  hideTypingIndicator() {
    this.typingIndicator.style.display = "none";
  }

  showEscalationButton() {
    this.escalationSection.style.display = "block";
  }

  hideEscalationButton() {
    this.escalationSection.style.display = "none";
  }

  async escalateToAdmin() {
    if (!this.conversationId) {
      this.displayError(
        "Không thể liên hệ admin. Vui lòng gửi tin nhắn trước.",
      );
      return;
    }

    if (this.isProcessing) {
      return;
    }

    this.isProcessing = true;
    this.escalationBtn.disabled = true;

    try {
      const response = await fetch("/api/chat/escalate", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          conversationId: this.conversationId,
          reason: "Yêu cầu hỗ trợ từ admin",
        }),
      });

      if (!response.ok) {
        throw new Error("Không thể chuyển cho admin. Vui lòng thử lại.");
      }

      // Display confirmation message
      const confirmationDiv = document.createElement("div");
      confirmationDiv.className =
        "chat-widget__message chat-widget__message--ai";

      const bubbleDiv = document.createElement("div");
      bubbleDiv.className = "chat-widget__message-bubble";
      bubbleDiv.textContent =
        "Yêu cầu của bạn đã được chuyển đến admin. Chúng tôi sẽ phản hồi sớm nhất có thể.";

      confirmationDiv.appendChild(bubbleDiv);
      this.messagesContainer.appendChild(confirmationDiv);
      this.scrollToBottom();

      // Hide escalation button
      this.hideEscalationButton();

      // ── Start polling for admin replies in real-time ──
      if (this.conversationId && this.isAuthenticated) {
        try {
          const histRes = await fetch(`/api/chat/history/${this.conversationId}`);
          const msgs = histRes.ok ? await histRes.json() : [];
          this.startAdminReplyPolling(msgs.length);
        } catch (e) {
          this.startAdminReplyPolling(0);
        }
      }
    } catch (error) {
      console.error("Error escalating to admin:", error);
      this.displayError(error.message || "Đã xảy ra lỗi. Vui lòng thử lại.");
    } finally {
      this.isProcessing = false;
      this.escalationBtn.disabled = false;
    }
  }

  async loadConversationHistory() {
    try {
      // Get list of conversations
      const conversationsResponse = await fetch("/api/chat/conversations");

      if (!conversationsResponse.ok) {
        return; // Silently fail for unauthenticated users
      }

      const conversations = await conversationsResponse.json();

      if (conversations.length === 0) {
        return;
      }

      // Load the most recent conversation
      const latestConversation = conversations[0];
      this.conversationId = latestConversation.id;
      sessionStorage.setItem("chatConversationId", latestConversation.id);

      // Load messages for this conversation
      const historyResponse = await fetch(
        `/api/chat/history/${latestConversation.id}`,
      );

      if (!historyResponse.ok) {
        return;
      }

      const messages = await historyResponse.json();

      // Clear welcome message
      const welcomeMsg = this.messagesContainer.querySelector(
        ".chat-widget__welcome",
      );
      if (welcomeMsg) {
        welcomeMsg.remove();
      }

      // Display all messages
      messages.forEach((msg) => {
        this.displayMessage(
          msg.senderType,
          msg.messageText,
          new Date(msg.createdAt),
        );
      });

      // ── Start polling for admin replies (conversation may already be escalated) ──
      this.startAdminReplyPolling(messages.length);

    } catch (error) {
      console.error("Error loading conversation history:", error);
      // Silently fail - don't disrupt user experience
    }
  }

  getSenderLabel(senderType) {
    switch (senderType) {
      case "User":
        return "Bạn";
      case "AI":
        return "Trợ lý AI";
      case "Admin":
        return "Admin";
      default:
        return senderType;
    }
  }

  /**
   * Start real-time polling for Admin replies after escalation.
   * Uses /AdminChat/PollAdminReplies endpoint (no auth required).
   * Works for both authenticated users and guests.
   */
  startAdminReplyPolling(initialCount) {
    if (this.adminPollingTimer) return; // already running
    if (!this.conversationId) return;

    // Track the last server time returned by the poll endpoint
    this.adminPollSince = new Date().toISOString();

    this.adminPollingTimer = setInterval(async () => {
      if (!this.conversationId) return;
      try {
        const since = encodeURIComponent(this.adminPollSince);
        const res = await fetch(`/AdminChat/PollAdminReplies/${this.conversationId}?since=${since}`);
        if (!res.ok) return;
        const data = await res.json();

        if (data.messages && data.messages.length > 0) {
          data.messages.forEach(msg => {
            this.displayMessage('Admin', msg.messageText, new Date(msg.createdAt));
          });
          this.scrollToBottom();
        }

        // Advance the since timestamp so we don't re-fetch old messages
        if (data.serverTime) {
          this.adminPollSince = data.serverTime;
        }

        // Handle conversation closed by admin
        if (data.status === "Closed") {
          clearInterval(this.adminPollingTimer);
          this.adminPollingTimer = null;
          this.conversationId = null;
          sessionStorage.removeItem("chatConversationId");

          const closedDiv = document.createElement("div");
          closedDiv.className = "chat-widget__message chat-widget__message--ai";
          const bubbleDiv = document.createElement("div");
          bubbleDiv.className = "chat-widget__message-bubble";
          bubbleDiv.textContent = "Admin đã kết thúc cuộc trò chuyện. Bạn hiện đang trò chuyện với Trợ lý AI.";
          closedDiv.appendChild(bubbleDiv);
          this.messagesContainer.appendChild(closedDiv);
          this.scrollToBottom();
        }
      } catch (e) { /* silent */ }
    }, 3000);
  }

  formatTime(timestamp) {
    let dateStr = timestamp;
    if (typeof dateStr === 'string' && !dateStr.endsWith('Z')) dateStr += 'Z';
    const date = new Date(dateStr);
    const hours = date.getHours().toString().padStart(2, "0");
    const minutes = date.getMinutes().toString().padStart(2, "0");
    return `${hours}:${minutes}`;
  }

  scrollToBottom() {
    this.messagesContainer.scrollTop = this.messagesContainer.scrollHeight;
  }
}

// Initialize chat widget when DOM is ready
if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", () => {
    new ChatWidget();
  });
} else {
  new ChatWidget();
}
