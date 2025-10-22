use serde::{Deserialize, Serialize};
use super::status::FileStatus;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RepositoryInfo {
    pub path: String,
    pub name: String,
    pub current_branch: Option<String>,
    pub is_dirty: bool,
    pub uncommitted_changes: i32,
    pub untracked_files: i32,
    pub unpushed_commits: i32,
    pub ahead: i32,
    pub behind: i32,
    pub last_commit: Option<CommitInfo>,
    pub files: Vec<FileStatus>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CommitInfo {
    pub hash: String,
    pub short_hash: String,
    pub message: String,
    pub author: String,
    pub email: String,
    pub timestamp: i64,
}

impl RepositoryInfo {
    pub fn new(path: String, name: String) -> Self {
        Self {
            path,
            name,
            current_branch: None,
            is_dirty: false,
            uncommitted_changes: 0,
            untracked_files: 0,
            unpushed_commits: 0,
            ahead: 0,
            behind: 0,
            last_commit: None,
            files: Vec::new(),
        }
    }
}
