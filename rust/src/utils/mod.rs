pub mod path;

pub use path::*;

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::Path;

    #[test]
    fn test_get_repo_name() {
        let path = Path::new("/home/user/projects/my-repo");
        let name = get_repo_name(path);
        assert_eq!(name, "my-repo");
    }

    #[test]
    fn test_get_repo_name_with_trailing_slash() {
        let path = Path::new("/home/user/projects/my-repo/");
        let name = get_repo_name(path);
        assert_eq!(name, "my-repo");
    }

    #[test]
    fn test_get_repo_name_root() {
        let path = Path::new("/");
        let name = get_repo_name(path);
        assert!(!name.is_empty());
    }

    #[test]
    fn test_normalize_path_relative() {
        let result = normalize_path("./test");
        assert!(result.is_ok());
    }

    #[test]
    fn test_normalize_path_absolute() {
        let result = normalize_path("/tmp");
        assert!(result.is_ok());
    }

    #[test]
    fn test_path_to_string() {
        let path = Path::new("/home/user/test");
        let result = path_to_string(path);
        assert!(result.is_ok());
        assert!(result.unwrap().contains("test"));
    }
}
