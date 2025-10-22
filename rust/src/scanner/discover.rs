use crate::error::{GitError, Result};
use crate::utils::*;
use rayon::prelude::*;
use std::fs;
use std::path::{Path, PathBuf};

pub struct RepositoryScanner {
    max_depth: Option<usize>,
}

impl RepositoryScanner {
    const ABSOLUTE_MAX_DEPTH: usize = 50;

    pub fn new() -> Self {
        Self { max_depth: Some(20) }
    }

    pub fn with_max_depth(max_depth: usize) -> Self {
        let capped_depth = max_depth.min(Self::ABSOLUTE_MAX_DEPTH);
        Self {
            max_depth: Some(capped_depth),
        }
    }

    pub fn scan(&self, root_path: &str) -> Result<Vec<String>> {
        let root = normalize_path(root_path)?;

        if !root.exists() {
            return Err(GitError::PathError(format!(
                "Path does not exist: {}",
                root_path
            )));
        }

        let canonical = root.canonicalize().map_err(|_| {
            GitError::PathError("Invalid or inaccessible path".to_string())
        })?;

        let path_str = canonical.to_string_lossy();

        let forbidden_paths = [
            "/etc", "/sys", "/proc", "/dev", "/boot",
            "/System", "/private", "/var", "/usr/bin", "/usr/sbin",
            "C:\\Windows", "C:\\Program Files", "C:\\Program Files (x86)",
        ];

        for forbidden in &forbidden_paths {
            if path_str.starts_with(forbidden) {
                return Err(GitError::PathError(
                    "Access to system directories is not allowed".to_string()
                ));
            }
        }

        let mut repos = Vec::new();
        self.scan_recursive(&canonical, 0, &mut repos)?;

        Ok(repos)
    }

    fn scan_recursive(&self, path: &Path, depth: usize, repos: &mut Vec<String>) -> Result<()> {
        if let Some(max_depth) = self.max_depth {
            if depth > max_depth {
                return Ok(());
            }
        }

        if !path.is_dir() {
            return Ok(());
        }

        let git_dir = path.join(".git");
        if git_dir.exists() && git_dir.is_dir() {
            if let Ok(path_str) = path_to_string(path) {
                repos.push(path_str);
            }
        }

        let entries = match fs::read_dir(path) {
            Ok(entries) => entries,
            Err(_) => return Ok(()),
        };

        for entry in entries.flatten() {
            let entry_path = entry.path();

            if entry_path.is_dir() {
                let dir_name = entry_path
                    .file_name()
                    .and_then(|n| n.to_str())
                    .unwrap_or("");

                if dir_name.starts_with('.') && dir_name != ".git" {
                    continue;
                }

                if should_skip_dir(dir_name) {
                    continue;
                }

                self.scan_recursive(&entry_path, depth + 1, repos)?;
            }
        }

        Ok(())
    }

    pub fn scan_parallel(&self, root_path: &str) -> Result<Vec<String>> {
        let root = normalize_path(root_path)?;

        if !root.exists() {
            return Err(GitError::PathError(format!(
                "Path does not exist: {}",
                root_path
            )));
        }

        let canonical = root.canonicalize().map_err(|_| {
            GitError::PathError("Invalid or inaccessible path".to_string())
        })?;

        let path_str = canonical.to_string_lossy();

        let forbidden_paths = [
            "/etc", "/sys", "/proc", "/dev", "/boot",
            "/System", "/private", "/var", "/usr/bin", "/usr/sbin",
            "C:\\Windows", "C:\\Program Files", "C:\\Program Files (x86)",
        ];

        for forbidden in &forbidden_paths {
            if path_str.starts_with(forbidden) {
                return Err(GitError::PathError(
                    "Access to system directories is not allowed".to_string()
                ));
            }
        }

        let repos = self.scan_parallel_recursive(&canonical, 0)?;

        Ok(repos)
    }

    fn scan_parallel_recursive(&self, path: &Path, depth: usize) -> Result<Vec<String>> {
        if let Some(max_depth) = self.max_depth {
            if depth > max_depth {
                return Ok(Vec::new());
            }
        }

        if !path.is_dir() {
            return Ok(Vec::new());
        }

        let mut repos = Vec::new();

        let git_dir = path.join(".git");
        if git_dir.exists() && git_dir.is_dir() {
            if let Ok(path_str) = path_to_string(path) {
                repos.push(path_str);
            }
        }

        let entries: Vec<PathBuf> = match fs::read_dir(path) {
            Ok(entries) => entries
                .flatten()
                .map(|e| e.path())
                .filter(|p| {
                    p.is_dir()
                        && !p
                            .file_name()
                            .and_then(|n| n.to_str())
                            .map(|name| {
                                (name.starts_with('.') && name != ".git") || should_skip_dir(name)
                            })
                            .unwrap_or(true)
                })
                .collect(),
            Err(_) => return Ok(repos),
        };

        let child_repos: Vec<Vec<String>> = entries
            .par_iter()
            .filter_map(|entry_path| self.scan_parallel_recursive(entry_path, depth + 1).ok())
            .collect();

        for mut child_repo_list in child_repos {
            repos.append(&mut child_repo_list);
        }

        Ok(repos)
    }
}

impl Default for RepositoryScanner {
    fn default() -> Self {
        Self::new()
    }
}

fn should_skip_dir(name: &str) -> bool {
    matches!(
        name,
        "node_modules"
            | "target"
            | "build"
            | ".dart_tool"
            | ".gradle"
            | ".idea"
            | ".vscode"
            | "vendor"
            | "dist"
            | "out"
            | "__pycache__"
    )
}

pub fn scan_repositories(root_path: String) -> Result<Vec<String>> {
    let scanner = RepositoryScanner::new();
    scanner.scan_parallel(&root_path)
}
