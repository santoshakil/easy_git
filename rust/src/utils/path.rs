use crate::error::{GitError, Result};
use std::path::{Path, PathBuf};

pub fn normalize_path(path: &str) -> Result<PathBuf> {
    let path = Path::new(path);

    if path.is_absolute() {
        Ok(path.to_path_buf())
    } else {
        std::env::current_dir()
            .map_err(GitError::Io)
            .map(|cwd| cwd.join(path))
    }
}

pub fn path_to_string(path: &Path) -> Result<String> {
    path.to_str()
        .ok_or_else(|| GitError::PathError("Invalid UTF-8 in path".to_string()))
        .map(|s| s.to_string())
}

pub fn get_repo_name(path: &Path) -> String {
    path.file_name()
        .and_then(|name| name.to_str())
        .unwrap_or("unknown")
        .to_string()
}

pub fn parent_path(path: &Path) -> Option<PathBuf> {
    path.parent().map(|p| p.to_path_buf())
}
