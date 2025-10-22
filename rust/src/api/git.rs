use crate::models::*;
use crate::scanner;
use crate::git;

#[flutter_rust_bridge::frb]
pub fn scan_repositories(root_path: String) -> anyhow::Result<Vec<String>> {
    scanner::scan_repositories(root_path).map_err(|e| anyhow::anyhow!("{}", e))
}

#[flutter_rust_bridge::frb]
pub fn get_repository_info(path: String) -> anyhow::Result<RepositoryInfo> {
    git::get_repository_info(path).map_err(|e| anyhow::anyhow!("{}", e))
}

#[flutter_rust_bridge::frb]
pub fn get_repository_status(path: String) -> anyhow::Result<RepoStatus> {
    git::get_repository_status(path).map_err(|e| anyhow::anyhow!("{}", e))
}

#[flutter_rust_bridge::frb]
pub fn get_multiple_repository_info(paths: Vec<String>) -> anyhow::Result<Vec<RepositoryInfo>> {
    use rayon::prelude::*;

    let results: Vec<RepositoryInfo> = paths
        .par_iter()
        .filter_map(|path| git::get_repository_info(path.clone()).ok())
        .collect();

    Ok(results)
}

#[flutter_rust_bridge::frb]
pub fn commit_repository(path: String, message: String) -> anyhow::Result<String> {
    git::commit_repository(path, message).map_err(|e| anyhow::anyhow!("{}", e))
}

#[flutter_rust_bridge::frb]
pub fn commit_multiple_repositories(paths: Vec<String>, message: String) -> anyhow::Result<Vec<String>> {
    git::commit_multiple_repositories(paths, message).map_err(|e| anyhow::anyhow!("{}", e))
}

#[flutter_rust_bridge::frb]
pub fn push_repository(path: String) -> anyhow::Result<()> {
    git::push_repository(path).map_err(|e| anyhow::anyhow!("{}", e))
}

#[flutter_rust_bridge::frb]
pub fn fetch_repository(path: String) -> anyhow::Result<()> {
    git::fetch_repository(path).map_err(|e| anyhow::anyhow!("{}", e))
}

#[flutter_rust_bridge::frb]
pub fn pull_repository(path: String) -> anyhow::Result<()> {
    git::pull_repository(path).map_err(|e| anyhow::anyhow!("{}", e))
}

#[flutter_rust_bridge::frb]
pub fn fetch_multiple_repositories(paths: Vec<String>) -> anyhow::Result<Vec<String>> {
    git::fetch_multiple_repositories(paths).map_err(|e| anyhow::anyhow!("{}", e))
}

#[flutter_rust_bridge::frb]
pub fn push_multiple_repositories(paths: Vec<String>) -> anyhow::Result<Vec<String>> {
    git::push_multiple_repositories(paths).map_err(|e| anyhow::anyhow!("{}", e))
}

#[flutter_rust_bridge::frb]
pub fn pull_multiple_repositories(paths: Vec<String>) -> anyhow::Result<Vec<String>> {
    git::pull_multiple_repositories(paths).map_err(|e| anyhow::anyhow!("{}", e))
}

#[flutter_rust_bridge::frb]
pub fn discard_repository_changes(path: String) -> anyhow::Result<()> {
    git::discard_repository_changes(path).map_err(|e| anyhow::anyhow!("{}", e))
}

#[flutter_rust_bridge::frb]
pub fn discard_multiple_repositories(paths: Vec<String>) -> anyhow::Result<Vec<String>> {
    git::discard_multiple_repositories(paths).map_err(|e| anyhow::anyhow!("{}", e))
}
