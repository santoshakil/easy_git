use rust_lib_easy_git::git::repository::pull_repository;

fn main() {
    println!("Testing pull operation...");

    let path = "/path/to/your/repository".to_string();

    match pull_repository(path.clone()) {
        Ok(_) => println!("✓ Successfully pulled {}", path),
        Err(e) => {
            eprintln!("✗ Failed to pull {}: {:?}", path, e);
            std::process::exit(1);
        }
    }

    println!("\nCheck /tmp/easy_git_ssh_debug.log for details");
}
