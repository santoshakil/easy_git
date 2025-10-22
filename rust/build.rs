fn main() {
    if cfg!(target_os = "macos") {
        println!("cargo:rustc-link-lib=z");
        println!("cargo:rustc-link-lib=iconv");
    }
}
