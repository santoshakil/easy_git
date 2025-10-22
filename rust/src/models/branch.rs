use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BranchInfo {
    pub name: String,
    pub is_current: bool,
    pub is_remote: bool,
    pub upstream: Option<String>,
    pub ahead: i32,
    pub behind: i32,
    pub last_commit_hash: Option<String>,
}

impl BranchInfo {
    pub fn new(name: String) -> Self {
        Self {
            name,
            is_current: false,
            is_remote: false,
            upstream: None,
            ahead: 0,
            behind: 0,
            last_commit_hash: None,
        }
    }
}
