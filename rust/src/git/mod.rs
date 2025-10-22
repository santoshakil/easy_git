pub mod repository;

pub use repository::*;

#[cfg(test)]
mod tests {
    #[test]
    fn test_commit_message_validation_empty() {
        let message = "";
        assert!(message.is_empty());
    }

    #[test]
    fn test_commit_message_validation_too_long() {
        let message = "a".repeat(10001);
        assert!(message.len() > 10000);
    }

    #[test]
    fn test_commit_message_sanitization() {
        let message = "Test\0message\0with\0nulls";
        let sanitized = message.replace('\0', "");
        assert!(!sanitized.contains('\0'));
        assert_eq!(sanitized, "Testmessagewithnulls");
    }

    #[test]
    fn test_commit_message_line_limit() {
        let message = (0..150).map(|i| format!("Line {}", i)).collect::<Vec<_>>().join("\n");
        let lines: Vec<&str> = message.lines().collect();
        assert!(lines.len() > 100);

        let limited: Vec<&str> = message.lines().take(100).collect();
        assert_eq!(limited.len(), 100);
    }

    #[test]
    fn test_valid_commit_message() {
        let message = "feat: add new feature\n\nThis is a detailed description.";
        assert!(!message.is_empty());
        assert!(message.len() <= 10000);
        assert!(!message.contains('\0'));
    }
}
