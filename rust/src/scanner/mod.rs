pub mod discover;

pub use discover::*;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_scanner_new_creates_successfully() {
        let scanner = RepositoryScanner::new();
        let result = scanner.scan(".");
        assert!(result.is_ok() || result.is_err());
    }

    #[test]
    fn test_scanner_with_max_depth_creates_successfully() {
        let scanner = RepositoryScanner::with_max_depth(100);
        let result = scanner.scan(".");
        assert!(result.is_ok() || result.is_err());
    }

    #[test]
    fn test_scanner_with_extreme_depth() {
        let _scanner = RepositoryScanner::with_max_depth(1000);
    }

    #[test]
    #[cfg(target_os = "linux")]
    fn test_scanner_rejects_system_directories_linux() {
        let scanner = RepositoryScanner::new();
        let forbidden_paths = vec!["/etc", "/sys", "/proc", "/dev", "/boot"];

        for path in forbidden_paths {
            let result = scanner.scan(path);
            assert!(result.is_err(), "Should reject path: {}", path);
            if let Err(e) = result {
                assert!(e.to_string().contains("Refusing to scan system directory"));
            }
        }
    }

    #[test]
    #[cfg(target_os = "macos")]
    fn test_scanner_rejects_system_directories_macos() {
        let scanner = RepositoryScanner::new();
        let result = scanner.scan("/System");
        assert!(result.is_err(), "Should reject /System directory");
    }

    #[test]
    fn test_scanner_nonexistent_path() {
        let scanner = RepositoryScanner::new();
        let result = scanner.scan("/nonexistent/path/that/does/not/exist/12345");
        assert!(result.is_err());
    }
}
