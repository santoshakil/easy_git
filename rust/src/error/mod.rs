use thiserror::Error;

#[derive(Error, Debug)]
pub enum GitError {
    #[error("Repository not found at path: {0}")]
    RepoNotFound(String),

    #[error("Invalid repository: {0}")]
    InvalidRepo(String),

    #[error("Git operation failed: {0}")]
    OperationFailed(String),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Git2 error: {0}")]
    Git2(#[from] git2::Error),

    #[error("Path error: {0}")]
    PathError(String),

    #[error("UTF-8 conversion error: {0}")]
    Utf8(#[from] std::str::Utf8Error),

    #[error("String conversion error: {0}")]
    FromUtf8(#[from] std::string::FromUtf8Error),

    #[error("No HEAD found")]
    NoHead,

    #[error("Detached HEAD state")]
    DetachedHead,

    #[error("No remote configured")]
    NoRemote,

    #[error("Branch not found: {0}")]
    BranchNotFound(String),

    #[error("Merge conflict detected")]
    MergeConflict,

    #[error("Working directory is dirty")]
    DirtyWorkingDir,
}

pub type Result<T> = std::result::Result<T, GitError>;
