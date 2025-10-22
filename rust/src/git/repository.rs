use crate::error::{GitError, Result};
use crate::models::*;
use crate::utils::*;
use git2::{BranchType, Cred, FetchOptions, PushOptions, RemoteCallbacks, Repository, StatusOptions};
use std::path::Path;

fn log_error(operation: &str, _path: &str, _error: &dyn std::fmt::Display) {
    eprintln!("{} operation failed", operation);
}

pub struct GitRepository {
    repo: Repository,
    path: String,
}

impl GitRepository {
    pub fn open(path: &str) -> Result<Self> {
        let normalized_path = normalize_path(path)?;
        let repo = Repository::open(&normalized_path)?;
        let path_str = path_to_string(&normalized_path)?;

        Ok(Self {
            repo,
            path: path_str,
        })
    }

    pub fn get_info(&self) -> Result<RepositoryInfo> {
        let name = get_repo_name(Path::new(&self.path));
        let mut info = RepositoryInfo::new(self.path.clone(), name);

        info.current_branch = self.get_current_branch().ok();

        let statuses = self.get_status()?;
        info.is_dirty = !statuses.is_clean;
        info.uncommitted_changes = statuses
            .files
            .iter()
            .filter(|f| f.status != FileStatusKind::Untracked)
            .count()
            .try_into()
            .unwrap_or(i32::MAX);
        info.untracked_files = statuses
            .files
            .iter()
            .filter(|f| f.status == FileStatusKind::Untracked)
            .count()
            .try_into()
            .unwrap_or(i32::MAX);
        info.files = statuses.files;

        if let Ok(head) = self.repo.head() {
            if let Ok(commit) = head.peel_to_commit() {
                info.last_commit = Some(CommitInfo {
                    hash: commit.id().to_string(),
                    short_hash: format!("{:.7}", commit.id()),
                    message: commit.message().unwrap_or("").to_string(),
                    author: commit.author().name().unwrap_or("").to_string(),
                    email: commit.author().email().unwrap_or("").to_string(),
                    timestamp: commit.time().seconds(),
                });
            }
        }

        if let Ok((ahead, behind)) = self.get_ahead_behind() {
            info.ahead = ahead;
            info.behind = behind;
            info.unpushed_commits = ahead;
        }

        Ok(info)
    }

    pub fn get_current_branch(&self) -> Result<String> {
        let head = self.repo.head()?;

        if !head.is_branch() {
            return Err(GitError::DetachedHead);
        }

        head.shorthand()
            .ok_or(GitError::NoHead)
            .map(|s| s.to_string())
    }

    pub fn get_status(&self) -> Result<RepoStatus> {
        let mut opts = StatusOptions::new();
        opts.include_untracked(true);
        opts.recurse_untracked_dirs(true);

        let statuses = self.repo.statuses(Some(&mut opts))?;

        let mut files = Vec::new();
        for entry in statuses.iter() {
            if let Some(path) = entry.path() {
                let status = entry.status();

                let file_status = if status.is_wt_new() || status.is_index_new() {
                    FileStatusKind::Untracked
                } else if status.is_wt_modified() || status.is_index_modified() {
                    FileStatusKind::Modified
                } else if status.is_wt_deleted() || status.is_index_deleted() {
                    FileStatusKind::Deleted
                } else if status.is_wt_renamed() || status.is_index_renamed() {
                    FileStatusKind::Renamed
                } else if status.is_conflicted() {
                    FileStatusKind::Conflicted
                } else {
                    FileStatusKind::Modified
                };

                files.push(FileStatus {
                    path: path.to_string(),
                    status: file_status,
                });
            }
        }

        Ok(RepoStatus {
            path: self.path.clone(),
            is_clean: files.is_empty(),
            files,
        })
    }

    pub fn get_ahead_behind(&self) -> Result<(i32, i32)> {
        let head = self.repo.head()?;

        let local_oid = head.target().ok_or(GitError::NoHead)?;

        let branch = self.repo.find_branch(
            head.shorthand().ok_or(GitError::NoHead)?,
            BranchType::Local,
        )?;

        let upstream = branch.upstream()?;
        let upstream_oid = upstream
            .get()
            .target()
            .ok_or(GitError::OperationFailed("No upstream target".to_string()))?;

        let (ahead, behind) = self.repo.graph_ahead_behind(local_oid, upstream_oid)?;

        Ok((
            ahead.try_into().unwrap_or(i32::MAX),
            behind.try_into().unwrap_or(i32::MAX)
        ))
    }

    pub fn get_branches(&self) -> Result<Vec<BranchInfo>> {
        let branches = self.repo.branches(None)?;

        let mut result = Vec::new();

        for (branch, _) in branches.flatten() {
            if let Ok(Some(name_str)) = branch.name() {
                let mut info = BranchInfo::new(name_str.to_string());
                info.is_current = branch.is_head();

                if let Ok(upstream) = branch.upstream() {
                    if let Ok(upstream_name) = upstream.name() {
                        info.upstream = upstream_name.map(|s| s.to_string());
                    }
                }

                result.push(info);
            }
        }

        Ok(result)
    }

    pub fn stage_all(&mut self) -> Result<()> {
        let mut index = self.repo.index()?;
        index.add_all(["*"].iter(), git2::IndexAddOption::DEFAULT, None)?;
        index.write()?;
        Ok(())
    }

    pub fn commit(&mut self, message: &str) -> Result<String> {
        if message.is_empty() {
            return Err(GitError::OperationFailed("Commit message cannot be empty".to_string()));
        }
        if message.len() > 10000 {
            return Err(GitError::OperationFailed("Commit message too long (max 10000 characters)".to_string()));
        }

        let sanitized = message.replace('\0', "").lines()
            .take(100)
            .collect::<Vec<_>>()
            .join("\n");

        let mut index = self.repo.index()?;
        let oid = index.write_tree()?;
        let tree = self.repo.find_tree(oid)?;

        let head = self.repo.head()?;
        let parent_commit = head.peel_to_commit()?;

        let sig = self.repo.signature()?;

        let commit_oid = self.repo.commit(
            Some("HEAD"),
            &sig,
            &sig,
            &sanitized,
            &tree,
            &[&parent_commit],
        )?;

        Ok(commit_oid.to_string())
    }

    pub fn commit_all(&mut self, message: &str) -> Result<String> {
        self.stage_all()?;
        self.commit(message)
    }

    fn create_callbacks<'a>() -> RemoteCallbacks<'a> {
        let mut callbacks = RemoteCallbacks::new();
        callbacks.credentials(|url, username_from_url, allowed_types| {
            if allowed_types.contains(git2::CredentialType::SSH_KEY) {
                let username = username_from_url.unwrap_or("git");

                let home = std::env::var("HOME")
                    .or_else(|_| std::env::var("USERPROFILE"))
                    .unwrap_or_else(|_| {
                        log_error("SSH key setup", "", &"Could not determine home directory");
                        String::from("")
                    });

                if home.is_empty() {
                    return Cred::ssh_key_from_agent(username);
                }

                let ssh_dir = format!("{}/.ssh", home);

                let key_paths = [
                    format!("{}/id_ed25519", ssh_dir),
                    format!("{}/id_rsa", ssh_dir),
                    format!("{}/id_ecdsa", ssh_dir),
                ];

                for key_path in &key_paths {
                    let private_key = std::path::Path::new(key_path);
                    if private_key.exists() {
                        let public_key_path = format!("{}.pub", key_path);
                        let public_key = std::path::Path::new(&public_key_path);
                        let pub_key_option = if public_key.exists() {
                            Some(public_key)
                        } else {
                            None
                        };

                        if let Ok(cred) = Cred::ssh_key(username, pub_key_option, private_key, None) {
                            return Ok(cred);
                        }
                    }
                }

                Cred::ssh_key_from_agent(username)
            } else {
                use std::process::{Command, Stdio};
                use std::io::Write;

                fn sanitize_url(url: &str) -> Option<String> {
                    if !url.starts_with("http://") &&
                       !url.starts_with("https://") &&
                       !url.starts_with("git://") &&
                       !url.starts_with("ssh://") {
                        return None;
                    }

                    let sanitized = url
                        .replace(";", "")
                        .replace("|", "")
                        .replace("&", "")
                        .replace("$", "")
                        .replace("`", "")
                        .replace("\n", "")
                        .replace("\r", "");

                    if sanitized.len() > 2048 {
                        return None;
                    }

                    Some(sanitized)
                }

                let sanitized_url = match sanitize_url(url) {
                    Some(u) => u,
                    None => return Cred::default(),
                };

                let input = format!("url={}\n\n", sanitized_url);

                match Command::new("git")
                    .args(["credential", "fill"])
                    .stdin(Stdio::piped())
                    .stdout(Stdio::piped())
                    .stderr(Stdio::null())
                    .spawn()
                {
                    Ok(mut child) => {
                        if let Some(mut stdin) = child.stdin.take() {
                            let _ = stdin.write_all(input.as_bytes());
                        }

                        match child.wait_with_output() {
                            Ok(output) if output.status.success() => {
                                let stdout = String::from_utf8_lossy(&output.stdout);
                                let mut username = None;
                                let mut password = None;

                                for line in stdout.lines() {
                                    if let Some(value) = line.strip_prefix("username=") {
                                        username = Some(value.to_string());
                                    } else if let Some(value) = line.strip_prefix("password=") {
                                        password = Some(value.to_string());
                                    }
                                }

                                match (username, password) {
                                    (Some(u), Some(p)) => Cred::userpass_plaintext(&u, &p),
                                    _ => Cred::default(),
                                }
                            },
                            _ => Cred::default(),
                        }
                    },
                    Err(_) => Cred::default(),
                }
            }
        });

        callbacks
    }

    pub fn push(&self) -> Result<()> {
        let mut remote = self.repo.find_remote("origin")?;

        let head = self.repo.head()?;
        let branch_name = head
            .shorthand()
            .ok_or(GitError::OperationFailed("No branch name".to_string()))?;

        let refspec = format!("refs/heads/{}:refs/heads/{}", branch_name, branch_name);

        let mut push_options = PushOptions::new();
        push_options.remote_callbacks(Self::create_callbacks());

        remote.push(&[&refspec], Some(&mut push_options))?;

        Ok(())
    }

    pub fn fetch(&self) -> Result<()> {
        let mut remote = self.repo.find_remote("origin")?;

        let mut fetch_options = FetchOptions::new();
        fetch_options.remote_callbacks(Self::create_callbacks());

        remote.fetch(&[] as &[&str], Some(&mut fetch_options), None)?;

        Ok(())
    }

    pub fn pull(&mut self) -> Result<()> {
        let mut remote = self.repo.find_remote("origin")?;

        let head = self.repo.head()?;
        let branch_name = head
            .shorthand()
            .ok_or(GitError::OperationFailed("No branch name".to_string()))?;

        let refspec = format!("+refs/heads/{}:refs/remotes/origin/{}", branch_name, branch_name);

        let mut fetch_options = FetchOptions::new();
        fetch_options.remote_callbacks(Self::create_callbacks());

        remote.fetch(&[&refspec], Some(&mut fetch_options), None)?;

        let fetch_head = self.repo.find_reference("FETCH_HEAD")?;
        let fetch_commit = self.repo.reference_to_annotated_commit(&fetch_head)?;

        let analysis = self.repo.merge_analysis(&[&fetch_commit])?;

        if analysis.0.is_up_to_date() {
            return Ok(());
        }

        if analysis.0.is_fast_forward() {
            let refname = format!("refs/heads/{}", branch_name);
            let mut reference = self.repo.find_reference(&refname)?;
            reference.set_target(fetch_commit.id(), "Fast-forward")?;
            self.repo.set_head(&refname)?;
            self.repo.checkout_head(Some(git2::build::CheckoutBuilder::default().force()))?;
        } else {
            return Err(GitError::OperationFailed("Pull requires merge, not implemented yet".to_string()));
        }

        Ok(())
    }

    pub fn discard_all_changes(&mut self) -> Result<()> {
        self.repo.checkout_head(Some(
            git2::build::CheckoutBuilder::default()
                .force()
                .remove_untracked(true)
        ))?;
        Ok(())
    }
}

pub fn get_repository_info(path: String) -> Result<RepositoryInfo> {
    let repo = GitRepository::open(&path)?;
    repo.get_info()
}

pub fn get_repository_status(path: String) -> Result<RepoStatus> {
    let repo = GitRepository::open(&path)?;
    repo.get_status()
}

pub fn commit_repository(path: String, message: String) -> Result<String> {
    let mut repo = GitRepository::open(&path)?;
    repo.commit_all(&message)
}

pub fn commit_multiple_repositories(paths: Vec<String>, message: String) -> Result<Vec<String>> {
    use rayon::prelude::*;

    let results: Vec<String> = paths
        .par_iter()
        .filter_map(|path| {
            match GitRepository::open(path) {
                Ok(mut repo) => match repo.commit_all(&message) {
                    Ok(_) => Some(path.clone()),
                    Err(e) => {
                        log_error("Commit", path, &e);
                        None
                    }
                },
                Err(e) => {
                    log_error("Open repository", path, &e);
                    None
                }
            }
        })
        .collect();

    Ok(results)
}

pub fn push_repository(path: String) -> Result<()> {
    let repo = GitRepository::open(&path)?;
    repo.push()
}

pub fn fetch_repository(path: String) -> Result<()> {
    let repo = GitRepository::open(&path)?;
    repo.fetch()
}

pub fn pull_repository(path: String) -> Result<()> {
    let mut repo = GitRepository::open(&path)?;
    repo.pull()
}

pub fn fetch_multiple_repositories(paths: Vec<String>) -> Result<Vec<String>> {
    use rayon::prelude::*;
    use std::collections::HashSet;

    let unique_paths: HashSet<_> = paths.into_iter().collect();

    let results: Vec<String> = unique_paths
        .par_iter()
        .filter_map(|path| {
            match GitRepository::open(path) {
                Ok(repo) => match repo.fetch() {
                    Ok(_) => Some(path.clone()),
                    Err(e) => {
                        log_error("Fetch", path, &e);
                        None
                    }
                },
                Err(e) => {
                    log_error("Open repository", path, &e);
                    None
                }
            }
        })
        .collect();

    Ok(results)
}

pub fn push_multiple_repositories(paths: Vec<String>) -> Result<Vec<String>> {
    use rayon::prelude::*;

    let results: Vec<String> = paths
        .par_iter()
        .filter_map(|path| {
            match GitRepository::open(path) {
                Ok(repo) => match repo.push() {
                    Ok(_) => Some(path.clone()),
                    Err(e) => {
                        log_error("Push", path, &e);
                        None
                    }
                },
                Err(e) => {
                    log_error("Open repository", path, &e);
                    None
                }
            }
        })
        .collect();

    Ok(results)
}

pub fn pull_multiple_repositories(paths: Vec<String>) -> Result<Vec<String>> {
    use rayon::prelude::*;

    let results: Vec<String> = paths
        .par_iter()
        .filter_map(|path| {
            match GitRepository::open(path) {
                Ok(mut repo) => match repo.pull() {
                    Ok(_) => Some(path.clone()),
                    Err(e) => {
                        log_error("Pull", path, &e);
                        None
                    }
                },
                Err(e) => {
                    log_error("Open repository", path, &e);
                    None
                }
            }
        })
        .collect();

    Ok(results)
}

pub fn discard_repository_changes(path: String) -> Result<()> {
    let mut repo = GitRepository::open(&path)?;
    repo.discard_all_changes()
}

pub fn discard_multiple_repositories(paths: Vec<String>) -> Result<Vec<String>> {
    use rayon::prelude::*;

    let results: Vec<String> = paths
        .par_iter()
        .filter_map(|path| {
            let mut repo = GitRepository::open(path).ok()?;
            repo.discard_all_changes().ok()?;
            Some(path.clone())
        })
        .collect();

    Ok(results)
}
